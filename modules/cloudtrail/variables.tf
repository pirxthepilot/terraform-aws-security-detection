variable "cloudtrail_s3_bucket_prefix" {
  default     = "tf-cloudtrail"
  description = "Bucket name prefix"
}

variable "cloudtrail_name" {
  default     = "tf-security-detection"
  description = "Name of the trail"
}
