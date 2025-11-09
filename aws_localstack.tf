variable "aws_region" {
  description = "Region placeholder"
  type        = string
  default     = "us-east-1"
}

variable "localstack_base_url" {
  description = "Base URL to LocalStack Edge (e.g., https://<ngrok-host>/localstack). No trailing spaces."
  type        = string
}

variable "bucket_suffix" {
  description = "Optional suffix to avoid bucket name collisions per stack"
  type        = string
  default     = ""
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

locals {
  bucket_name = "demo-iac-bucket-localstack-001${var.bucket_suffix}"
}

resource "aws_s3_bucket" "demo-iac" {
  bucket = local.bucket_name
}

resource "aws_s3_object" "welcome" {
  bucket  = aws_s3_bucket.demo-iac.id
  key     = "hello.txt"
  content = "Hello from Terraform via LocalStack!"
}

output "s3_bucket_name" {
  value = aws_s3_bucket.demo-iac.bucket
}
