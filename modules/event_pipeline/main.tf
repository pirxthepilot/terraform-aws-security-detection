variable name {}


/*
*  SNS
*/

resource "aws_sns_topic" "security_event" {
  name_prefix  = "${var.name}-"
  display_name = var.event_title
}


/*
*  Cloudwatch
*/

resource "aws_cloudwatch_event_rule" "security_event" {
  name_prefix = "${var.name}-"
  description = var.event_description

  event_pattern = var.event_pattern
}

resource "aws_cloudwatch_event_target" "sns" {
  rule = aws_cloudwatch_event_rule.security_event.name
  #target_id = aws_sns_topic.security_event.id
  arn = aws_sns_topic.security_event.arn
}
