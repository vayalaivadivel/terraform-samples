variable "ec2-ami-id" {
  description = "Image id"
  type        = string
  default     = "ami-0bdd88bd06d16ba03"
}
variable "ec2-type" {
  description = "Ec2 type"
  type        = string
  default     = "t2.micro"
}

variable "access-key-name" {
  description = "Access key name"
  type        = string
  default     = "common-key"
}

variable "subnet-cidr-block" {
  description = "Access key name"
  type        = string
  default     = "10.0.0.0/24"
}

variable "vpc-cidr-block" {
  description = "Access key name"
  type        = string
  default     = "10.0.0.0/16"
}