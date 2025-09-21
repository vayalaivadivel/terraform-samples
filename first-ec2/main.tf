provider "aws" {
  region  = "us-east-1"
  profile = "devops"
}
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}
resource "aws_instance" "name" {
  ami           = "ami-0b09ffb6d8b58ca91"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.my_subnet.id
  tags = {
    Name = "MyFirstEC2"
    Environment = "Dev"
  }
  user_data = file("jenkins.sh")
}
resource "aws_s3_bucket" "my_bucket" {
  bucket = "mybuc00000000000000"  # must be globally unique
 
  tags = {
    Name        = "MyBucket"
    Environment = "Dev"
  }
}
