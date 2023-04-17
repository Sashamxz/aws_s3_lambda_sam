provider "aws" {
  profile = "default"
  region = "eu-north-1"
}

# Create s3 bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket = "s3log-file-journal"
}

# s3 bucket arn
output "s3_bucket_arn" {
  value = aws_s3_bucket.log_bucket.arn
}



# Export Lambda function ARN as Terraform output
output "lambda_function_arn" {
  value = data.aws_cloudformation_stack.existing_stack.outputs["LambdaFunctionArn"]
}

# Define local variable for event JSON
locals {
  event_json = {
    source = ["aws.s3"]
    detail = {
      eventSource = ["s3.amazonaws.com"]
      eventName = ["PutObject"]
      requestParameters = {
        bucketName = ["s3log-file-journal"]
      }
    }
  }
}

# create rule
resource "aws_cloudwatch_event_rule" "s3_event_rule" {
  name          = element(local.event_json.source, 0)
  event_pattern = jsonencode(local.event_json)
}

# Create EventBridge target
resource "aws_cloudwatch_event_target" "lambda_event_target" {
  rule      = aws_cloudwatch_event_rule.s3_event_rule.name
  role_arn  = aws_iam_role.eventbridge_role.arn
  arn       = data.aws_cloudformation_stack.existing_stack.outputs["LambdaFunctionArn"]
  target_id = "lambda-target"
}

# Create s3 bucket notification for EventBridge
resource "aws_s3_bucket_notification" "s3_bucket_eventbridge" {
  bucket      = "s3log-file-journal"
  eventbridge = true
}

# # ROLES

# Define IAM role for EventBridge
resource "aws_iam_role" "eventbridge_role" {
  name_prefix = "eventbridge-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

# Create Lambda permission for EventBridge
resource "aws_lambda_permission" "eventbridge_permission" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_cloudformation_stack.existing_stack.outputs["LambdaFunctionArn"]
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_event_rule.arn
}