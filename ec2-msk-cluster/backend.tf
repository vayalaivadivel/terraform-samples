# terraform init -reconfigure -force-copy
# terraform state push terraform.tfstate
terraform {
  backend "s3" {
    bucket  = "vadivel-tf-state-buc"
    key     = "ec2-msk-cluster/terraform.tfstate"
    region  = "us-east-1"
    profile = "devops"
    encrypt = true
  }
}