output "lambda_function_arn" {
  value = aws_lambda_function.security_detection.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.security_detection.function_name
}
