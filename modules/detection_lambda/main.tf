/*
*  The Lambda function
*/

resource "aws_lambda_function" "security_detection" {
  function_name = var.name
  filename      = var.filename
  handler       = var.handler
  runtime       = var.runtime
  role          = aws_iam_role.security_detection.arn
  description   = var.description

  source_code_hash = filebase64sha256("${var.filename}")

  depends_on = [
    aws_cloudwatch_log_group.security_detection,
    aws_iam_role_policy_attachment.security_detection
  ]
}

/*
*  Cloudwatch log group
*/

resource "aws_cloudwatch_log_group" "security_detection" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 5
}

/*
*  IAM
*/

resource "aws_iam_role" "security_detection" {
  name_prefix = var.name

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "security_detection" {
  name_prefix = var.name
  description = "IAM policy for logging from a lambda"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "security_detection" {
  role       = aws_iam_role.security_detection.name
  policy_arn = aws_iam_policy.security_detection.arn
}