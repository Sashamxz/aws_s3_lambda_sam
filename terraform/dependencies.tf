# Reference the existing CloudFormation stack
data "aws_cloudformation_stack" "existing_stack" {
  name = "lambda-s3-envt-trigger" 
}