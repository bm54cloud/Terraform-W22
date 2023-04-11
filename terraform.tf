#Declare S3 backend
#https://developer.hashicorp.com/terraform/language/settings/backends/s3
terraform {
  backend "s3" {
    bucket = "terraform-s3backend-w22project"
    key    = "State-Files/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "Terraform-s3-backened-w22"
    encrypt        = true
  }
}