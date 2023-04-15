provider "aws" {
  profile = "default"
}

# Create s3 bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket = "s3log-file-journal"
}

# s3 bucket
output "s3_bucket_arn" {
  value = aws_s3_bucket.log_bucket.arn
}

# Reference the existing CloudFormation stack
data "aws_cloudformation_stack" "existing_stack" {
  name = "lambda-s3-envt-trigger" 
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
  description   = local.event_json.detail.eventSource[0]
  event_pattern = jsonencode(local.event_json)
}

# Create EventBridge target
resource "aws_cloudwatch_event_target" "lambda_event_target" {
  rule      = aws_cloudwatch_event_rule.s3_event_rule.name
  arn       = data.aws_cloudformation_stack.existing_stack.outputs["LambdaFunctionArn"]
  target_id = "lambda-target"
}

# Add S3 bucket notification configuration
resource "aws_s3_bucket_notification_configuration" "this" {
  rule {
    status = "Enabled"

    filter {
      prefix = ""

      tags {
        Source = aws_s3_bucket.log_bucket.arn
      }
    }

    # Add EventBridge target
    destination {
      arn = aws_eventbridge_event_bus.this.arn
    }
  }
}
resource "aws_eventbridge_event_bus" "my_event_bus" {
  name = "my-event-bus"
}