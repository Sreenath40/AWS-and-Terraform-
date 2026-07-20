provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "sreenath" {
  instance_type = "t2.micro"
  ami           = "ami-0b6d9d3d33ba97d99"
  subnet_id     = "subnet-02015f3f2480d1ac8"
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "sreenath-s3-demo-xyz"

}
  resource "aws_dynamodb_table" "terraformlock" {
    name         = "terraform-lock"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "LockID"

    attribute {
      name = "LockID"
      type = "S"
    }
    
  }