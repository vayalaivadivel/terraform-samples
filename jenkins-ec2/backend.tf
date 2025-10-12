terraform {
  backend "s3" {
    bucket  = "vadivel-tf-state-buc-jenkins"
    key     = "jenkins/terraform.tfstate"
    region  = "us-east-1"
    profile = "devops"
    encrypt = true
  }
}
