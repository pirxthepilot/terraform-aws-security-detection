variable "sns_topic_name_prefix" {
  default     = "security-events"
  description = "Prefix of SNS topic name"
}

variable "sns_topic_display_name" {
  default     = "Security Events"
  description = "Display name of SNS topic"
}

variable "module_depends_on" {
  type        = any
  default     = null
  description = "Workaround for module dependencies"
}
