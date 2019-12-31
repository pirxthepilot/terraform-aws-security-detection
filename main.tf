/*
*  Provider
*/

provider "aws" {
  profile = "default"
  region  = var.region
}


/*
*  VPC
*/

#  Spin up the test VPC whose default security group will
#  be used for this deployment
resource "aws_vpc" "security_poc" {
  cidr_block = "10.234.0.0/24"

  tags = {
    Name = "Security Detection PoC"
  }
}

# Get the ARN of the default security group
data "aws_security_group" "security_poc" {
  id = aws_vpc.security_poc.default_security_group_id
}


/*
*  CloudTrail (includes S3 bucket setup)
*/

module "cloudtrail" {
  source = "./modules/cloudtrail"
  name   = "security-detection"
}


/*
*  Event Pipeline module for security group ingress rule changes
*/

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
      "AuthorizeSecurityGroupIngress"
    ],
    "requestParameters": {
      "groupId": [
        "${aws_vpc.security_poc.default_security_group_id}"
      ]
    }
  }
}
PATTERN
}


/*
*  Lambda function for security group ingress rule changes
*/

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
      "Resource": "${data.aws_security_group.security_poc.arn}",
      "Effect": "Allow"
    }
  ]
}
POLICY
}

# Subscribe the function to the SNS topic
resource "aws_sns_topic_subscription" "sg_ingress" {
  topic_arn = module.sg_ingress_rule_event.sns_topic_arn
  protocol  = "lambda"
  endpoint  = module.sg_ingress_rule_lambda.lambda_function_arn
}

# Give the SNS topic permission to invoke the function
resource "aws_lambda_permission" "sg_ingress" {
  action        = "lambda:InvokeFunction"
  function_name = module.sg_ingress_rule_lambda.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = module.sg_ingress_rule_event.sns_topic_arn
}
