output security_group_id {
  value = module.test_vpc.default_security_group_id
}

output cloudtrail_s3_bucket_id {
  value = module.cloudtrail.cloudtrail_s3_bucket_id
}

output security_group_event_topic_id {
  value = module.security_group_event.sns_topic_id
}
