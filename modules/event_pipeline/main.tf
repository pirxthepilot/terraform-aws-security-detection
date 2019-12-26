/*
*  Cloudwatch
*/

resource "aws_cloudwatch_event_rule" "security_event" {
  name_prefix = "${var.name}-"
  description = var.event_description
  #role_arn    = aws_iam_role.cloudwatch_publish_to_sns.arn

  event_pattern = var.event_pattern
}

resource "aws_cloudwatch_event_target" "sns" {
  rule = aws_cloudwatch_event_rule.security_event.name
  arn  = aws_sns_topic.security_event.arn
}


/*
*  SNS
*/

resource "aws_sns_topic" "security_event" {
  name_prefix  = "${var.name}-"
  display_name = var.event_title
}

resource "aws_sns_topic_policy" "security_event" {
  arn = aws_sns_topic.security_event.arn

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudwatchRule_${aws_cloudwatch_event_rule.security_event.name}",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.security_event.arn}"
    }
  ]
}
POLICY
}
