resource "aws_cloudfront_function" "beta_service_viewer_request" {
  name    = "beta-service-viewer-request"
  runtime = "cloudfront-js-2.0"
  comment = "Beta service viewer request (basic auth, credentials from Secrets Manager)"
  publish = true
  code = templatefile("${path.root}/cloudfront-functions/viewer-request.js.tpl", {
    # The secret is stored as a ready-made JSON object ({"user":"pass"}), so it
    # is passed straight through rather than via jsonencode(a map) like the
    # alpha function does with its plaintext tfvars-sourced map.
    basic_auth_user_list = data.aws_secretsmanager_secret_version.beta_cloudfront_basic_auth.secret_string
  })
}
