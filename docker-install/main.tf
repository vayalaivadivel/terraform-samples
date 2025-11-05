# 1. Create the main VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc-cidr-block

  tags = {
    Name = "docker-vpc"
  }
}

# 2. Create a Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet-cidr-block
  map_public_ip_on_launch = true # Automatically assign public IPs to instances

  tags = {
    Name = "public-subnet-example"
  }
}

# 3. Create an Internet Gateway (IGW)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# 4. Create a Route Table for public access
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # Traffic to anywhere goes to the IGW
    gateway_id = aws_internet_gateway.gw.id
  }
}

# 5. Associate the Route Table with the Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 6. Security group
# Security Group to allow SSH and HTTP traffic
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_security_group"
  description = "Allow SSH inbound traffic and HTTP 8080"
  vpc_id      = aws_vpc.main.id

  # Ingress rule for SSH (port 22)
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # CRITICAL: Replace "YOUR_PUBLIC_IP_HERE/32" with your actual public IP + /32
    # Use 0.0.0.0/0 only if you accept the security risks.
    cidr_blocks = ["103.48.69.138/32"] 
  }

  # Ingress rule for HTTP (port 8080)
  ingress {
    description = "HTTP 8080 from anywhere"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule: allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 7. Instance creation (The 'vpc_security_group_ids' attribute links the SG to the instance)
resource "aws_instance" "docker_host" {
  ami                         = var.ec2-ami-id 
  instance_type               = var.ec2-type
  key_name                    = var.access-key-name
  associate_public_ip_address = true
  user_data                   = file("docker-install.sh")
  subnet_id                   = aws_subnet.public.id

  # CRITICAL FIX: Associate the security group with the instance
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "DockerHost"
  }
}

# Output the SSH connection command for easy access
output "ssh_command" {
  description = "SSH command to connect to the instance (assuming 'ec2-user' and a local key file)"
  value       = "ssh -i ~/.ssh/${var.access-key-name}.pem ec2-user@${aws_instance.docker_host.public_ip}"
}