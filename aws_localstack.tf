variable "aws_region" {
  description = "Region placeholder"
  type        = string
  default     = "us-east-1"
}

variable "localstack_base_url" {
  description = "Base URL to LocalStack Edge (e.g., https://<ngrok-host>/localstack). No trailing slash."
  type        = string
}

provider "aws" {
  region                      = var.aws_region
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  endpoints {
    apigateway     = var.localstack_base_url
    cloudformation = var.localstack_base_url
    cloudwatch     = var.localstack_base_url
    dynamodb       = var.localstack_base_url
    ec2            = var.localstack_base_url
    ecr            = var.localstack_base_url
    ecs            = var.localstack_base_url
    iam            = var.localstack_base_url
    lambda         = var.localstack_base_url
    logs           = var.localstack_base_url
    s3             = var.localstack_base_url
    secretsmanager = var.localstack_base_url
    sns            = var.localstack_base_url
    sqs            = var.localstack_base_url
    ssm            = var.localstack_base_url
    sts            = var.localstack_base_url
  }
}
