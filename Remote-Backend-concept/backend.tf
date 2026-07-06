terraform {
  backend "s3" {
    bucket         = "sreenath-s3-demo-xyz" # change this
    key            = "sree/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}