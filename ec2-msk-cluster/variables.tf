############################
# Variables
############################
variable "region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
  default = "common-key"
}

variable "profile" {
  description = "Name of the profile"
  type        = string
  default = "devops"
}