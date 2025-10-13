resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name        = "k8s"
    Environment = "dev"
  }
  enable_dns_support   = true #VPC can resolve DNS names (required for almost all network communication).
  enable_dns_hostnames = true
}

# Internet Gateway
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = {
    Name = "k8s-igw"
  }

}

resource "aws_subnet" "k8s_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "k8s-pub-subnet"
  }
}

# Route Table
resource "aws_route_table" "k8s_pub_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_igw.id
  }

  tags = {
    Name = "k8s-pub-rt"
  }
}


# Associate Route Table with Subnet
resource "aws_route_table_association" "k8s_pub_assoc" {
  subnet_id      = aws_subnet.k8s_subnet.id
  route_table_id = aws_route_table.k8s_pub_rt.id
}

resource "aws_security_group" "k8s_sec_group" {
  name        = "k8s_sec"
  description = "This is the security group"
  vpc_id      = aws_vpc.k8s_vpc.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_network_acl" "public_nacl" {
  vpc_id     = aws_vpc.k8s_vpc.id
  subnet_ids = [aws_subnet.k8s_subnet.id]

  # Allow all inbound traffic (simpler for public subnet)
  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Allow all outbound traffic
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "k8s-pub-nacl"
  }
}


# IAM Role for EC2
resource "aws_iam_role" "ec2_admin_role" {
  name = "ec2-admin-role"

  # Trust policy that allows the EC2 service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AWS-managed AdministratorAccess policy to the role
resource "aws_iam_role_policy_attachment" "ec2_admin_attachment" {
  role       = aws_iam_role.ec2_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# IAM Instance Profile
# This is required to attach the IAM role to the EC2 instance
resource "aws_iam_instance_profile" "ec2_admin_profile" {
  name = "ec2-admin-profile"
  role = aws_iam_role.ec2_admin_role.name
}


resource "aws_instance" "k8s_ec2" {
  ami                    = "ami-0b09ffb6d8b58ca91"
  instance_type          = "t2.small"
  subnet_id              = aws_subnet.k8s_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sec_group.id]
  key_name               = "common-key"
  tags = {
    Name        = "k8s-ec2"
    Environment = "Dev"
  }
  iam_instance_profile = aws_iam_instance_profile.ec2_admin_profile.name

  associate_public_ip_address = true
}