variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "multi-region-demo"
}

variable "addition_region" {
  description = "Region for addition instance"
  type        = string
  default     = "us-east-1"
}

variable "deletion_region" {
  description = "Region for deletion instance"
  type        = string
  default     = "us-east-2"
}

variable "production_region" {
  description = "Region for production Auto Scaling workload"
  type        = string
  default     = "ap-south-1"
}

variable "modification_region" {
  description = "Region for modification instance"
  type        = string
  default     = "eu-west-1"
}

variable "addition_ami_id" {
  description = "AMI ID for us-east-1"
  type        = string
}

variable "deletion_ami_id" {
  description = "AMI ID for us-east-2"
  type        = string
}

variable "production_ami_id" {
  description = "AMI ID for ap-south-1"
  type        = string
}

variable "modification_ami_id" {
  description = "AMI ID for eu-west-1"
  type        = string
}

variable "instance_type" {
  description = "Default EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "modified_instance_type" {
  description = "Modified EC2 instance type for modification instance"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Your public IP range for SSH access"
  type        = list(string)
}

variable "allowed_http_cidr" {
  description = "CIDR allowed for HTTP access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "s3_bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for LB"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum Auto Scaling instances"
  type        = number
  default     = 1
}

variable "asg_desired_capacity" {
  description = "Desired Auto Scaling instances"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum Auto Scaling instances"
  type        = number
  default     = 3
}