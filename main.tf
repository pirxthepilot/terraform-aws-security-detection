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

# Get the ARN of the default security group
data "aws_security_group" "security_demo" {
  id = aws_vpc.security_demo.default_security_group_id
}

# Enable Cloudtrail (includes S3 bucket setup)
module "cloudtrail" {
  source = "./modules/cloudtrail"
  name   = "security-detection"
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

# Lambda function for detection and response
module "sg_ingress_rule_lambda" {
  source      = "./modules/detection_lambda"
  name        = "sg-ingress-rule"
  description = "Ingress rule checker"

  filename = "./pkgtmp/sg_ingress_checker.zip"
  handler  = "sg_ingress_checker.lambda_handler"

  custom_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:RevokeSecurityGroupIngress"
      ],
      "Resource": "${data.aws_security_group.security_demo.arn}",
      "Effect": "Allow"
    }
  ]
}
POLICY
}

# Subscribe the lambda to the SNS topic
resource "aws_sns_topic_subscription" "sg_ingress" {
  topic_arn = module.sg_ingress_rule_event.sns_topic_arn
  protocol  = "lambda"
  endpoint  = module.sg_ingress_rule_lambda.lambda_function_arn
}

resource "aws_lambda_permission" "sg_ingress" {
  action        = "lambda:InvokeFunction"
  function_name = module.sg_ingress_rule_lambda.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = module.sg_ingress_rule_event.sns_topic_arn
}
