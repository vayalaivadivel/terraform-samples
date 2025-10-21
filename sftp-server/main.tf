###############################################################
# TERRAFORM & PROVIDER
###############################################################
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

###############################################################
# NETWORK: VPC, SUBNET, IGW, ROUTE TABLE, SG
###############################################################
resource "aws_vpc" "sftp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project}-vpc" }
}

resource "aws_subnet" "sftp_subnet" {
  vpc_id                  = aws_vpc.sftp_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone
  tags                    = { Name = "${var.project}-subnet" }
}

resource "aws_internet_gateway" "sftp_igw" {
  vpc_id = aws_vpc.sftp_vpc.id
  tags   = { Name = "${var.project}-igw" }
}

resource "aws_route_table" "sftp_rt" {
  vpc_id = aws_vpc.sftp_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sftp_igw.id
  }
  tags = { Name = "${var.project}-route-table" }
}

resource "aws_route_table_association" "sftp_rta" {
  subnet_id      = aws_subnet.sftp_subnet.id
  route_table_id = aws_route_table.sftp_rt.id
}

###############################################################
# SECURITY GROUP
###############################################################
resource "aws_security_group" "sftp_sg" {
  name        = "${var.project}-sg"
  description = "Allow SSH and SFTP"
  vpc_id      = aws_vpc.sftp_vpc.id

  # SSH from your laptop
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # SFTP (port 22) from bastion subnet
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-sg" }
}

###############################################################
# EFS
###############################################################
resource "aws_efs_file_system" "sftp_efs" {
  creation_token = "${var.project}-efs"
  tags           = { Name = "${var.project}-efs" }
}

resource "aws_efs_mount_target" "sftp_efs_mount" {
  file_system_id  = aws_efs_file_system.sftp_efs.id
  subnet_id       = aws_subnet.sftp_subnet.id
  security_groups = [aws_security_group.sftp_sg.id]
}

###############################################################
# IAM ROLE FOR TRANSFER FAMILY
###############################################################
resource "aws_iam_role" "transfer_logging_role" {
  name = "${var.project}-logging-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "transfer.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "transfer_logging_policy" {
  name = "${var.project}-logging-policy"
  role = aws_iam_role.transfer_logging_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:DescribeFileSystems"
        ],
        Resource = aws_efs_file_system.sftp_efs.arn
      }
    ]
  })
}

###############################################################
# BASTION HOST USING EXISTING KEY
###############################################################
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.sftp_subnet.id
  vpc_security_group_ids      = [aws_security_group.sftp_sg.id]
  key_name                    = var.existing_key_name
  associate_public_ip_address = true

  tags = { Name = "${var.project}-bastion" }
}

###############################################################
# TRANSFER FAMILY SFTP SERVER (VPC)
###############################################################
resource "aws_transfer_server" "sftp_server" {
  identity_provider_type = "SERVICE_MANAGED"
  endpoint_type          = "VPC"
  protocols              = ["SFTP"]
  logging_role           = aws_iam_role.transfer_logging_role.arn

  endpoint_details {
    vpc_id             = aws_vpc.sftp_vpc.id
    subnet_ids         = [aws_subnet.sftp_subnet.id]
    security_group_ids = [aws_security_group.sftp_sg.id]
  }

  tags = { Name = "${var.project}-sftp-server" }
}

###############################################################
# IAM ROLE FOR SFTP USER
###############################################################
resource "aws_iam_role" "transfer_user_role" {
  name = "transfer-user-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "transfer.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "transfer_user_policy" {
  role = aws_iam_role.transfer_user_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:DescribeFileSystems"
        ],
        Resource = aws_efs_file_system.sftp_efs.arn
      }
    ]
  })
}

###############################################################
# TLS KEY GENERATION FOR SFTP USER
###############################################################
resource "tls_private_key" "sftp_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "sftp_private_key" {
  content  = tls_private_key.sftp_key.private_key_pem
  filename = "${path.module}/sftp_test_key.pem"
}

###############################################################
# SFTP USER WITH CUSTOM HOME DIRECTORY "/feeds"
###############################################################
resource "aws_transfer_user" "sftp_user" {
  server_id      = aws_transfer_server.sftp_server.id
  user_name      = var.sftp_username
  role           = aws_iam_role.transfer_user_role.arn
  home_directory = "/feeds"
  tags           = { Name = var.sftp_username }
}

resource "aws_transfer_ssh_key" "sftp_user_key" {
  server_id = aws_transfer_server.sftp_server.id
  user_name = aws_transfer_user.sftp_user.user_name
  body      = tls_private_key.sftp_key.public_key_openssh
}

