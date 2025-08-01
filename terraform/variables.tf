variable "project_name" {
  description = "Project Name - Will be added as a Tag for all resources, and used as a prefix for resources"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "s3_models_store_bucket_name" {
  description = "Name of S3 bucket to create to store models"
  type        = string
}

variable "app_codepipeline_codestar_connection_arn" {
  description = "Codestar Connection ARN, which is configured to allow triggers from the app repo"
  type        = string
}

variable "app_github_repo_owner" {
  description = "App GitHub repository owner"
  type        = string
}

variable "app_github_repo_name" {
  description = "App GitHub repository name"
  type        = string
}

variable "app_cloudfront_tls_certificate_arn" {
  description = "App CloudFront TLS certificate ARN"
  type        = string
}

variable "app_cloudfront_aliases" {
  description = "App CloudFront aliases"
  type        = list(string)
}

variable "app_cloudfront_basic_auth_user_list" {
  description = "map of user/passwords for CloudFront basic auth"
  type        = map(string)
}

variable "app_alb_tls_certificate_arn" {
  description = "App ALB TLS certificate ARN"
  type        = string
}
