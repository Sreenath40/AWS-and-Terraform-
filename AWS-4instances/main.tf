terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# -----------------------------
# Providers for 4 AWS Regions
# -----------------------------
provider "aws" {
  alias  = "addition"
  region = var.addition_region
}

provider "aws" {
  alias  = "deletion"
  region = var.deletion_region
}

provider "aws" {
  alias  = "production"
  region = var.production_region
}

provider "aws" {
  alias  = "modification"
  region = var.modification_region
}

# -----------------------------
# S3 Bucket - Storage
# -----------------------------
resource "aws_s3_bucket" "app_storage" {
  provider = aws.production
  bucket   = var.s3_bucket_name

  tags = {
    Name        = var.s3_bucket_name
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "app_storage_versioning" {
  provider = aws.production
  bucket   = aws_s3_bucket.app_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_storage_encryption" {
  provider = aws.production
  bucket   = aws_s3_bucket.app_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -----------------------------
# IAM Role and Policies for EC2
# -----------------------------
resource "aws_iam_role" "ec2_role" {
  provider = aws.production
  name     = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-ec2-role"
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_policy" "ec2_s3_cloudwatch_policy" {
  provider = aws.production
  name     = "${var.project_name}-ec2-s3-cloudwatch-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3AccessToAppBucket"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.app_storage.arn,
          "${aws_s3_bucket.app_storage.arn}/*"
        ]
      },
      {
        Sid    = "AllowCloudWatchLogsAndMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  provider   = aws.production
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_s3_cloudwatch_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  provider = aws.production
  name     = "${var.project_name}-ec2-profile"
  role     = aws_iam_role.ec2_role.name
}

# ==========================================================
# REGION 1: ADDITION INSTANCE - us-east-1
# ==========================================================

data "aws_vpc" "addition_default" {
  provider = aws.addition
  default  = true
}

data "aws_subnets" "addition_default" {
  provider = aws.addition

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.addition_default.id]
  }
}

resource "aws_security_group" "addition_sg" {
  provider    = aws.addition
  name        = "${var.project_name}-addition-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.addition_default.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr
  }

  ingress {
    description = "SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-addition-sg"
    Environment = "addition"
  }
}

resource "aws_instance" "addition_instance" {
  provider               = aws.addition
  ami                    = var.addition_ami_id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.addition_default.ids[0]
  vpc_security_group_ids = [aws_security_group.addition_sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl enable httpd
              systemctl start httpd
              echo "Addition instance - ${var.addition_region}" > /var/www/html/index.html
              EOF

  tags = {
    Name        = "${var.project_name}-addition-instance"
    Environment = "addition"
  }
}

resource "aws_lb" "addition_alb" {
  provider           = aws.addition
  name               = "${var.project_name}-addition-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.addition_sg.id]
  subnets            = data.aws_subnets.addition_default.ids

  tags = {
    Name        = "${var.project_name}-addition-alb"
    Environment = "addition"
  }
}

resource "aws_lb_target_group" "addition_tg" {
  provider = aws.addition
  name     = "${var.project_name}-addition-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.addition_default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "addition_attach" {
  provider         = aws.addition
  target_group_arn = aws_lb_target_group.addition_tg.arn
  target_id        = aws_instance.addition_instance.id
  port             = 80
}

resource "aws_lb_listener" "addition_listener" {
  provider          = aws.addition
  load_balancer_arn = aws_lb.addition_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.addition_tg.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "addition_cpu_alarm" {
  provider            = aws.addition
  alarm_name          = "${var.project_name}-addition-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Alarm when addition instance CPU exceeds 70%"

  dimensions = {
    InstanceId = aws_instance.addition_instance.id
  }
}

# ==========================================================
# REGION 2: DELETION INSTANCE - us-east-2
# ==========================================================

data "aws_vpc" "deletion_default" {
  provider = aws.deletion
  default  = true
}

data "aws_subnets" "deletion_default" {
  provider = aws.deletion

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.deletion_default.id]
  }
}

resource "aws_security_group" "deletion_sg" {
  provider    = aws.deletion
  name        = "${var.project_name}-deletion-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.deletion_default.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr
  }

  ingress {
    description = "SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "deletion_instance" {
  provider               = aws.deletion
  ami                    = var.deletion_ami_id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.deletion_default.ids[0]
  vpc_security_group_ids = [aws_security_group.deletion_sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl enable httpd
              systemctl start httpd
              echo "Deletion instance - ${var.deletion_region}" > /var/www/html/index.html
              EOF

  tags = {
    Name        = "${var.project_name}-deletion-instance"
    Environment = "deletion"
  }
}

resource "aws_cloudwatch_metric_alarm" "deletion_cpu_alarm" {
  provider            = aws.deletion
  alarm_name          = "${var.project_name}-deletion-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    InstanceId = aws_instance.deletion_instance.id
  }
}

# ==========================================================
# REGION 3: PRODUCTION INSTANCE + AUTOSCALING - ap-south-1
# ==========================================================

data "aws_vpc" "production_default" {
  provider = aws.production
  default  = true
}

data "aws_subnets" "production_default" {
  provider = aws.production

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.production_default.id]
  }
}

resource "aws_security_group" "production_sg" {
  provider    = aws.production
  name        = "${var.project_name}-production-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.production_default.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr
  }

  ingress {
    description = "SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "production_lt" {
  provider      = aws.production
  name_prefix   = "${var.project_name}-production-lt-"
  image_id      = var.production_ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.production_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl enable httpd
              systemctl start httpd
              echo "Production Auto Scaling instance - ${var.production_region}" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-production-asg-instance"
      Environment = "production"
    }
  }
}

resource "aws_lb" "production_alb" {
  provider           = aws.production
  name               = substr("${var.project_name}-prod-alb", 0, 32)
  load_balancer_type = "application"
  security_groups    = [aws_security_group.production_sg.id]
  subnets            = data.aws_subnets.production_default.ids

  tags = {
    Name        = "${var.project_name}-production-alb"
    Environment = "production"
  }
}

resource "aws_lb_target_group" "production_tg" {
  provider = aws.production
  name     = "${var.project_name}-production-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.production_default.id

  health_check {
    path     = "/"
    protocol = "HTTP"
    matcher  = "200"
  }
}

resource "aws_lb_listener" "production_listener" {
  provider          = aws.production
  load_balancer_arn = aws_lb.production_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.production_tg.arn
  }
}

resource "aws_autoscaling_group" "production_asg" {
  provider            = aws.production
  name                = "${var.project_name}-production-asg"
  desired_capacity    = var.asg_desired_capacity
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  vpc_zone_identifier = data.aws_subnets.production_default.ids
  target_group_arns   = [aws_lb_target_group.production_tg.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.production_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-production-asg"
    propagate_at_launch = true
  }
}

resource "aws_cloudwatch_metric_alarm" "production_asg_cpu_alarm" {
  provider            = aws.production
  alarm_name          = "${var.project_name}-production-asg-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.production_asg.name
  }
}

# ==========================================================
# REGION 4: MODIFICATION INSTANCE - eu-west-1
# ==========================================================

data "aws_vpc" "modification_default" {
  provider = aws.modification
  default  = true
}

data "aws_subnets" "modification_default" {
  provider = aws.modification

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.modification_default.id]
  }
}

resource "aws_security_group" "modification_sg" {
  provider    = aws.modification
  name        = "${var.project_name}-modification-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.modification_default.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr
  }

  ingress {
    description = "SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "modification_instance" {
  provider               = aws.modification
  ami                    = var.modification_ami_id
  instance_type          = var.modified_instance_type
  subnet_id              = data.aws_subnets.modification_default.ids[0]
  vpc_security_group_ids = [aws_security_group.modification_sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl enable httpd
              systemctl start httpd
              echo "Modification instance - ${var.modification_region}" > /var/www/html/index.html
              EOF

  tags = {
    Name        = "${var.project_name}-modification-instance"
    Environment = "modification"
  }
}

resource "aws_cloudwatch_metric_alarm" "modification_cpu_alarm" {
  provider            = aws.modification
  alarm_name          = "${var.project_name}-modification-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    InstanceId = aws_instance.modification_instance.id
  }
}

# -----------------------------
# Route 53 DNS Records
# -----------------------------
data "aws_route53_zone" "us-east-1" {
  provider     = aws.production
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "production_dns" {
  provider = aws.production
  zone_id  = data.aws_route53_zone.us-east-1.zone_id
  name     = "prod.${var.domain_name}"
  type     = "A"

  alias {
    name                   = aws_lb.production_alb.dns_name
    zone_id                = aws_lb.production_alb.zone_id
    evaluate_target_health = true
  }
}