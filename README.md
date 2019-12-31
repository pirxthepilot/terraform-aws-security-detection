# terraform-aws-security-detection

Proof-of-concept Terraform deployment of a security detection and response system in AWS

## Description

This project is based on the ideas from the article [“No Bad AWS Cloud Security Events Ever!” with help from Python, AWS Lambda, and SNS](https://medium.com/@_ashishpatel/no-bad-aws-cloud-security-events-ever-with-help-from-python-aws-lambda-and-sns-65c13f13189f) by [Ashish Patel](https://github.com/ashishpatel-git). In it, he demonstrated a way to implement a self-correcting security detection and response system in AWS.

My goal, in turn, was to fully automate a similar deployment using Terraform. This project provides all you need to spin up such an environment, which you can then trivially dismantle (and redeploy).


## Current Detections

Only one at the moment, but I am looking to add more!

| Blurb | Watched Events | Detection | Response |
| ----- | -------------- | --------- | -------- |
| Security Group Ingress Rule Check | `ec2:AuthorizeSecurityGroupIngress` | Ingress rules that allow open access from any IP | Log + Delete the offending rules |


## Components

These are currently all the things this Terraform project provides. These components integrate seamlessly together - no manual config needed.

### Test VPC

Creates a new VPC whose default security group is used for testing the detections. (No other VPC or security group is harmed in the making of this project.)

### CloudTrail

Creates a CloudTrail trail, including configuration of the destination S3 bucket. 

Managed by the [cloudtrail module](./modules/cloudtrail).

### CloudWatch event rules and targets

Creates CloudWatch event rules that watch for specific events (via CloudTrail logs) for security analysis. When such events are received, they get sent to their respective event targets - in this case, SNS topics.

Managed by the [event_pipeline module](./modules/event_pipeline).

### Simple Notification Service (SNS) topics and subscriptions

Creates SNS topics that receive events from CloudWatch. Later in the process, each Lambda function that performs actual detection and response subscribe to its respective topic.

It's worth noting that it would be simpler to do away with SNS and send events directly to Lambda from CloudWatch, but owing to the original article this project is based on, I've decided to keep it to sort of simulate an environment where, e.g. instead of CloudWatch, it's Splunk sending events (like in the article).

Managed by the [event_pipeline module](./modules/event_pipeline).

### Lambda functions

Deploys the Lambda functions that do most of the detection and response heavy lifting. Functions are subscribed to its respective SNS topic.

Managed by the [detection_lambda module](./modules/detection_lambda).

### IAM and permissions

Component deployments also include configuration of necessary IAM roles and policies as well as service-specific permissions. Without this, components won't be able to communicate and Lambda functions unable to perform remediation actions.


## Usage

First ensure you have the [Terraform CLI](https://www.terraform.io/downloads.html) installed.

Make sure you have credentials that can perform programmatic tasks with `AdministratorAccess` permissions. If you can run admin-level tasks from the AWS CLI, you are good to go.

To deploy, simply run:

```
make apply
```

Review the changes, enter `yes` when ready.

That's it! After Terraform completes, wait at least two minutes before doing tests.

To test out the system:

Find the newly created VPC. In its default security group, adding ingress rules that have open access from any IP will trigger violations.

Violations will be shown in the CloudWatch log group for the Lambda function. After a few seconds, the offending ingress rules will be deleted automatically from the security group.

Note that the Lambda function has whitelists that allow TCP and UDP ports, and ICMP to be excluded from triggering a violation. See the [python code](./lambda_functions/sg_ingress_checker/sg_ingress_checker.py) for more details.

PRO TIP: A nice alternative to viewing logs from AWS Console or AWS CLI is to use [awslogs](https://github.com/jorgebastida/awslogs) to tail the log stream, like so: 

```
awslogs get /aws/lambda/sg-ingress-rule --start 15m -w
```

Finally, clean up by running either `terraform destroy` or `make destroy`. This will delete ALL resources created by this project.


## References

* https://medium.com/@_ashishpatel/no-bad-aws-cloud-security-events-ever-with-help-from-python-aws-lambda-and-sns-65c13f13189f 
* https://aws.amazon.com/blogs/security/how-to-monitor-aws-account-configuration-changes-and-api-calls-to-amazon-ec2-security-groups/
* https://www.davidbegin.com/the-most-minimal-aws-lambda-function-with-python-terraform/
* https://dev.to/tbetous/how-to-make-conditionnal-resources-in-terraform-440n
* https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_RevokeSecurityGroupIngress.html
* https://www.terraform.io/docs/providers/aws/index.html
