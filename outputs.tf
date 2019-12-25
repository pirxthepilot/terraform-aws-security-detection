output security_group_id {
  value = module.test_vpc.default_security_group_id
}

output cloudtrail_s3_bucket_id {
  value = module.cloudtrail.cloudtrail_s3_bucket_id
}
