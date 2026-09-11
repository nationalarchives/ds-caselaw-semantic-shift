resource "aws_secretsmanager_secret" "beta_cloudfront_basic_auth" {
  name        = local.beta_cloudfront_basic_auth_secret_name
  description = "Beta CloudFront basic auth user list (JSON object of username to password). Terraform manages this secret container only; the value must be seeded/rotated out of band (see README) and is never stored in tfvars, code, or logs."

  recovery_window_in_days = 30

  tags = local.common_tags
}

# Reads whatever value is currently stored in Secrets Manager. On first apply,
# before the secret has been seeded, this data source will fail to resolve;
# see README.md "Beta CloudFront basic auth" for the required bootstrap steps.
data "aws_secretsmanager_secret_version" "beta_cloudfront_basic_auth" {
  secret_id = aws_secretsmanager_secret.beta_cloudfront_basic_auth.id
}
