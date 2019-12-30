output security_group_id {
  value = aws_vpc.security_poc.default_security_group_id
}

output cloudtrail_s3_bucket_id {
  value = module.cloudtrail.cloudtrail_s3_bucket_id
}

output sg_ingress_topic_arn {
  value = module.sg_ingress_rule_event.sns_topic_arn
}

output sg_ingress_lambda_arn {
  value = module.sg_ingress_rule_lambda.lambda_function_arn
}
