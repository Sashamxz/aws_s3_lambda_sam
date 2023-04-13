provider "aws" {
  profile = "default"
}


# aws cloudformation stack
data "aws_cloudformation_stack" "sam_stack" {
  name = "aws-sam-cli-managed-default"
}

# Export Lambda function ARN and  as Terraform outputs
output "lambda_function_arn" {
  value = data.aws_cloudformation_stack.sam_stack.outputs["MyFunctionArn"]
}


# Create s3 bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket = "log.file_journal"
}


# # Create EventBridge rule
# data "local_file" "event_json" {
#   filename = "../events/event.json"
# }

# resource "aws_cloudwatch_event_rule" "s3_event_rule" {
#   name          = jsondecode(data.local_file.event_json.content)["name"]
#   description   = jsondecode(data.local_file.event_json.content)["description"]
#   event_pattern = jsondecode(data.local_file.event_json.content)["event_pattern"]
# }


# # Create EventBridge target
# resource "aws_cloudwatch_event_target" "lambda_event_target" {
#   rule      = aws_cloudwatch_event_rule.s3_event_rule.name
#   arn       = aws_lambda_function.s3_lambda_log.arn
#   target_id = "lambda-target"
# }


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
