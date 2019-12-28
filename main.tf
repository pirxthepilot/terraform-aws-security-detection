# Provider details
provider "aws" {
  profile = "default"
  region  = var.region
}

# Spin up the test VPC whose default security group will
# will be used for this deployment
resource "aws_vpc" "security_demo" {
  cidr_block = "10.234.0.0/24"

  tags = {
    Name = "Security Detection Demo"
  }
}

# Enable Cloudtrail (includes S3 bucket setup)
module "cloudtrail" {
  source = "./modules/cloudtrail"
}

# Event Pipeline module for security group ingress rule changes
module "sg_ingress_rule_event" {
  source            = "./modules/event_pipeline"
  name              = "sg-ingress-rule"
  event_title       = "Security Group Ingress Rule Change"
  event_description = "Changes to ingress rules in security groups"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "ec2.amazonaws.com"
    ],
    "eventName": [
      "AuthorizeSecurityGroupIngress",
      "RevokeSecurityGroupIngress"
    ],
    "requestParameters": {
      "groupId": [
        "${aws_vpc.security_demo.default_security_group_id}"
      ]
    }
  }
}
PATTERN
}
