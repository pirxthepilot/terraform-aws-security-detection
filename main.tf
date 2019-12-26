# Provider details
provider "aws" {
  profile = "default"
  region  = var.region
}

# Spin up the test VPC whose default security
# group will be used for this deployment
module "test_vpc" {
  source = "./modules/test_vpc"

  cidr_block = "10.234.0.0/24"
}

# Enable Cloudtrail (includes S3 bucket setup)
module "cloudtrail" {
  source = "./modules/cloudtrail"
}

# Event Pipeline module for security group changes
module "security_group_event" {
  source            = "./modules/event_pipeline"
  name              = "security-group"
  event_title       = "Security Group Changes"
  event_description = "Watches changes to security groups"

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
        "${module.test_vpc.default_security_group_id}"
      ]
    }
  }
}
PATTERN
}
