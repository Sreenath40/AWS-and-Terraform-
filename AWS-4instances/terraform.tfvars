project_name = "sreenath-aws" # keep short so generated names fit limits
domain_name  = "srihari.shop"

addition_region     = "us-east-1"
deletion_region     = "us-east-2"
production_region   = "ap-south-1"
modification_region = "eu-west-1"

addition_ami_id     = "ami-02b64aa047cb5edf5"
deletion_ami_id     = "ami-028ba4d4ccb4b7b72"
production_ami_id   = "ami-035827357e3c7e810"
modification_ami_id = "ami-04bc53b7a499f5d37"

instance_type          = "t3.micro"
modified_instance_type = "t3.small"

key_name = "sreenath_kay678"

allowed_ssh_cidr = ["39.0.0.0/32"]

s3_bucket_name = "sreenatha-multi-region-demo-2026"

asg_min_size         = 1
asg_desired_capacity = 1
asg_max_size         = 3