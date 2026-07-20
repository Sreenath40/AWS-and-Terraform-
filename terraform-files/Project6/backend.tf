terraform {
  backend "s3" {
    key    = "sreenath/terraform.tfstate"
    bucket = "sreenath-s3-demo-xyz"
    region = "us-east-1"  
    dynamodb_table = "terraform-lock"  
  }
}