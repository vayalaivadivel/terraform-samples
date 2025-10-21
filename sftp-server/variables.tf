variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "us-east-1a"
}

variable "project" {
  description = "Prefix for resource naming"
  type        = string
  default     = "complete-sftp"
}

variable "sftp_username" {
  description = "Username for AWS Transfer Family SFTP"
  type        = string
  default     = "sftpuser"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file (.pub)"
  type        = string
}

variable "existing_key_name" {
  description = "Name of your existing AWS key pair to use for bastion"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the bastion host (e.g., Amazon Linux 2)"
  type        = string
}
variable "my_ip_cidr" { type = string }
