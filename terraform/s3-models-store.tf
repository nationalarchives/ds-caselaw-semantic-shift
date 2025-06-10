resource "aws_s3_bucket" "models_store" {
  bucket = local.s3_models_store_bucket_name
}

resource "aws_s3_bucket_policy" "models_store" {
  bucket = aws_s3_bucket.models_store.id

  policy = templatefile(
    "${path.root}/policies/s3-bucket-policy.json.tpl",
    {
      statement = <<EOT
      [
      ${templatefile("${path.root}/policies/s3-bucket-policy-statements/enforce-tls.json.tpl",
      {
        bucket_arn = aws_s3_bucket.models_store.arn
      }
  )}
      ]
      EOT
}
)
}

resource "aws_s3_bucket_public_access_block" "models_store" {
  bucket                  = aws_s3_bucket.models_store.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "models_store" {
  bucket = aws_s3_bucket.models_store.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "models_store" {
  bucket = aws_s3_bucket.models_store.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
