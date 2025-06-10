resource "aws_s3_bucket" "app_build_pipeline_artifact_store" {
  bucket = "${local.project_name}-app-build-pipeline-artifact-store"
}

resource "aws_s3_bucket_policy" "app_build_pipeline_artifact_store" {
  bucket = aws_s3_bucket.app_build_pipeline_artifact_store.id
  policy = templatefile(
    "${path.module}/policies/s3-bucket-policy.json.tpl",
    {
      statement = <<EOT
      [
      ${templatefile("${path.root}/policies/s3-bucket-policy-statements/enforce-tls.json.tpl",
      {
        bucket_arn = aws_s3_bucket.app_build_pipeline_artifact_store.arn
      }
  )}
      ]
      EOT
}
)
}

resource "aws_s3_bucket_public_access_block" "app_build_pipeline_artifact_store" {
  bucket                  = aws_s3_bucket.app_build_pipeline_artifact_store.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "app_build_pipeline_artifact_store" {
  bucket = aws_s3_bucket.app_build_pipeline_artifact_store.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_build_pipeline_artifact_store" {
  bucket = aws_s3_bucket.app_build_pipeline_artifact_store.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "app_build_pipeline_artifact_store" {
  bucket = aws_s3_bucket.app_build_pipeline_artifact_store.id

  rule {
    id = "transition-to-ia-then-glacier"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    filter {
      prefix = ""
    }

    status = "Enabled"
  }
}
