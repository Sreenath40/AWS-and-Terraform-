provider "aws" {
  region = "us-east-1"
}

module "ec2_instance" {
  source = "D:/terraform-files/Project5/modules-ec2_instance"

  ami_value        = "ami-0b6d9d3d33ba97d99"
  instance_type_value = "t2.micro"
  subnet_id_value     = "subnet-02015f3f2480d1ac8"
}