# Fetch the latest AMI ID for Ubuntu 20.04 from AWS
data "aws_ami" "ubuntu_ami" {
  filter {
    name   = "image-id"
    values = ["ami-053b0d53c279acc90"]
  }
  #   filter {
  #     name   = "root-device-type"
  #     values = ["ebs"]
  #   }

  #   filter {
  #     name   = "name"
  #     values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  #   }
  #   filter {
  #     name   = "virtualization-type"
  #     values = ["hvm"]
  #   }

  #   most_recent = true
  #   owners      = ["099720109477"]
}

# Data source for the hosted zone
data "aws_route53_zone" "hosted_zone" {
  name = var.domain_name
}
