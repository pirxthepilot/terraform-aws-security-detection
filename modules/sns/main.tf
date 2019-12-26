# SNS topic
resource "aws_sns_topic" "security_events" {
  name_prefix  = var.sns_topic_name_prefix
  display_name = var.sns_topic_display_name

  depends_on = [var.module_depends_on]
}
