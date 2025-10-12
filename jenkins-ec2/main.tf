
# create bucket
# aws s3api create-bucket \
#   --bucket vadivel-terraform-state-bucket-jenkins \
#   --region ap-south-1 \
#   --create-bucket-configuration LocationConstraint=ap-south-1 \
#   --profile devops

#enable versioning

# aws s3api put-bucket-versioning \
#   --bucket vadivel-terraform-state-bucket-jenkins \
#   --versioning-configuration Status=Enabled \
#   --profile devops


resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name        = "my-comp"
    Environment = "dev"
  }
  enable_dns_support   = true #VPC can resolve DNS names (required for almost all network communication).
  enable_dns_hostnames = true
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "main-igw"
  }

}

resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "public-subnet"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}


# Associate Route Table with Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "my_sec_group" {
  name        = "my_sec"
  description = "This is the security group"
  vpc_id      = aws_vpc.my_vpc.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
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
  vpc_id     = aws_vpc.my_vpc.id
  subnet_ids = [aws_subnet.my_subnet.id]

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
    Name = "public-nacl"
  }
}


resource "aws_instance" "name" {
  ami                    = "ami-0b09ffb6d8b58ca91"
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.my_sec_group.id]
  key_name               = "common-key"
  tags = {
    Name        = "terraform-ec2"
    Environment = "Dev"
  }
  associate_public_ip_address = true
  user_data                   = file("jenkins.sh")
}

data "external" "jenkins_password" {
  program = [
    "bash",
    "${path.module}/get_jenkins_password.sh",
    aws_instance.name.public_ip,
    var.ssh_key_path
  ]
  depends_on = [aws_instance.name]
}



data "aws_caller_identity" "current" {}
