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

# --- Beta app (caselaw-semantic-beta) ---
# Beta is a small, explicit second application sharing the existing ALB and
# CloudFront distribution via path-based routing at /beta. It intentionally
# does not generalise the app_* resources into a map; see AWS_BETA_DEPLOYMENT_PLAN.md.

variable "beta_github_repo_owner" {
  description = "Beta app GitHub repository owner"
  type        = string
  default     = "nationalarchives"
}

variable "beta_github_repo_name" {
  description = "Beta app GitHub repository name"
  type        = string
  default     = "da-caselaw-semantic-beta"
}

variable "beta_s3vectors_index_arn" {
  description = "ARN of the existing S3 Vectors index Beta queries at search time. Terraform does not create or populate this bucket/index; embedding upserts are managed out of band."
  type        = string
}

variable "beta_cloudfront_basic_auth_secret_name" {
  description = "Name of the Secrets Manager secret holding Beta's CloudFront basic auth user list (JSON object of username to password). Terraform manages the secret container; the secret value is provisioned/rotated out of band, never via tfvars."
  type        = string
  default     = "css-beta-cloudfront-basic-auth"
}

variable "beta_alb_health_check_path" {
  description = "ALB target group health check path for Beta (must include the /beta base path Streamlit is configured with)"
  type        = string
  default     = "/beta/_stcore/health"
}
