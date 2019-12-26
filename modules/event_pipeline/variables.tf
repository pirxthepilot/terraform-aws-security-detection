variable "event_title" {
  type        = string
  default     = null
  description = "Friendly name for the event (optional)"
}

variable "event_description" {
  type        = string
  default     = null
  description = "Description for the Cloudwatch rule (optional)"
}

variable "event_pattern" {
  type        = string
  description = "Event pattern JSON object"
}
