provider "aws" {
    region = "us-east-1"  
}

resource "aws_instance" "example" {
    ami           = "ami-0b6d9d3d33ba97d99"  # Specify an appropriate AMI ID
    instance_type = "t3.micro"
}
