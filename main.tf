terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "The AWS Region"
  default     = "us-east-1"
}

variable "domain_name" {
  type        = string
  description = "The domain name"
  default     = "django.bl4ko.com"
}

# Create ssh key pair
resource "aws_key_pair" "django" {
  key_name   = "django"
  public_key = file("~/.ssh/aws_django.pub")
}

# Create ec2 ubuntu instance
resource "aws_instance" "ec2" {
  ami                  = data.aws_ami.ubuntu_ami.id
  instance_type        = "t2.micro"
  iam_instance_profile = "EC2-SSM-Access-Role"

  user_data = base64encode(file("init.sh"))

  # Add keypair
  key_name = aws_key_pair.django.key_name

  # Add django security group
  vpc_security_group_ids = [aws_security_group.django.id]

  tags = {
    Name = "Django"
  }
}

output "public_dns" {
  value = aws_instance.ec2.public_dns
}

output "instance_id" {
  value = aws_instance.ec2.id
}
