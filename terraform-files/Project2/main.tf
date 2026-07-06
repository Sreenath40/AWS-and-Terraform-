provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow-ssh-http"
  description = "Allow SSH and HTTP"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_server" {
  ami                    = "ami-0b6d9d3d33ba97d99"
  instance_type          = "t3.micro"
  key_name               = "terraform-key"
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install nginx -y
              systemctl enable nginx
              systemctl start nginx

              echo "<h1>Nginx Installed Successfully using Terraform</h1>" > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "Terraform-EC2-Nginx"
  }
}

output "public_ip" {
  value = aws_instance.web_server.public_ip
}

output "website_url" {
  value = "http://${aws_instance.web_server.public_ip}"
}