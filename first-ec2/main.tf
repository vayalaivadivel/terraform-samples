resource "aws_vpc" "name" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "custom-vpc"
  }
}

resource "aws_subnet" "name" {
  cidr_block              = "10.0.0.0/17"
  vpc_id                  = aws_vpc.name.id
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "custom-subnet"
  }
}

resource "aws_internet_gateway" "name" {
  vpc_id = aws_vpc.name.id
  tags = {
    Name = "custom-igw"
  }
}
resource "aws_route_table" "name" {
  vpc_id = aws_vpc.name.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.name.id
  }
  tags = {
    Name = "custom-rt"
  }
}

resource "aws_route_table_association" "name" {
  subnet_id      = aws_subnet.name.id
  route_table_id = aws_route_table.name.id
}
resource "aws_security_group" "name" {
  name        = "custom-sg"
  description = "Security group"
  vpc_id      = aws_vpc.name.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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

resource "aws_instance" "name" {
  ami                    = "ami-0b09ffb6d8b58ca91"
  instance_type          = "t2.micro"
  key_name               = "common-key"
  subnet_id              = aws_subnet.name.id
  vpc_security_group_ids = [aws_security_group.name.id]
  tags = {
    Name        = "MyFirstEC2"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "terraform-statefile-bucket-091756093438"

  tags = {
    Name = "terraform-state"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}