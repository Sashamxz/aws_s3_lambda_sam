provider "aws" {
  profile = "default"
  region  = "us-west-2"
}


# Export Lambda function ARN and S3 bucket ARN as Terraform outputs
output "lambda_function_arn" {
  value = data.aws_cloudformation_stack.sam_stack_outputs.outputs["MyFunctionArn"]
}


# Create S3 bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket = "log.file_journal"
}


resource "aws_iam_role_policy_attachment" "s3_lambda_log_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.s3_lambda_log_role.name
}


# Create EventBridge rule
locals {
  event_rule = jsondecode(file("../events/event.json"))
}


resource "aws_cloudwatch_event_rule" "s3_event_rule" {
  name        = local.event_rule.name
  description = local.event_rule.description
  event_pattern = local.event_rule.event_pattern
}


# Create EventBridge target
resource "aws_cloudwatch_event_target" "lambda_event_target" {
  rule      = aws_cloudwatch_event_rule.s3_event_rule.name
  arn       = aws_lambda_function.s3_lambda_log.arn
  target_id = "lambda-target"
}


# Use SAM to package and deploy Lambda function
resource "aws_cloudformation_stack" "sam_stack" {
  name = "sam-stack"
  template_body = file("${path.module}/template.yaml")
  capabilities = ["CAPABILITY_IAM"]
}


# Use CloudFormation stack output to get Lambda function ARN
data "aws_cloudformation_stack" "sam_stack_outputs" {
  name = aws_cloudformation_stack.sam_stack.name
  output_key = "MyFunctionArn"
}


# Use CloudFormation stack output to get S3 bucket ARN
data "aws_s3_bucket_object" "log_bucket_objects" {
  bucket = aws_s3_bucket.log_bucket.id
  key    = "test.txt"

  depends_on = [
    aws_cloudformation_stack.sam_stack,
  ]
}





output "s3_bucket_arn" {
  value = aws_s3_bucket.log_bucket.arn
}
