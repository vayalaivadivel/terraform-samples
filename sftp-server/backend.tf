# terraform init -reconfigure -force-copy
# terraform state push terraform.tfstate
terraform {
  backend "s3" {
    bucket  = "vadivel-tf-state-buc"
    key     = "sftp-server/terraform.tfstate"
    region  = "us-east-1"
    profile = "devops"
    encrypt = true
  }
}