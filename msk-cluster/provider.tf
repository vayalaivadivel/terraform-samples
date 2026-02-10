

############################
# Provider
############################
provider "aws" {
  region = "us-east-1"
  profile = "devops"
}

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
