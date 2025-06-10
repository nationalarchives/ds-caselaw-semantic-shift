resource "aws_ecr_repository" "app" {
  name = "${local.project_name}-app"

  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = templatefile(
    "${path.root}/policies/ecr-policies/max-images.json.tpl",
    {
      max_images = 5
    }
  )
}
