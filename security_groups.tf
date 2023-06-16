variable "CLOUDFRONT_PREFIX_LIST_ID" {
  description = "CloudFront Prefix List ID"
  type        = string
  # aws ec2 describe-managed-prefix-lists
  # Search for "PrefixListName": "com.amazonaws.global.cloudfront.origin-facing"
  default = "pl-3b927c52"
}

resource "aws_security_group" "django" {
  name        = "django"
  description = "Django security group"
}

resource "aws_security_group_rule" "allow_cloudfront" {
  security_group_id = aws_security_group.django.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  prefix_list_ids   = [var.CLOUDFRONT_PREFIX_LIST_ID]
}

resource "aws_security_group_rule" "allow_all_outbound" {

  security_group_id = aws_security_group.django.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
