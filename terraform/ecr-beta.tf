module "beta_ecr" {
  source = "git::https://github.com/nationalarchives/da-terraform-modules.git//ecr?ref=9ae2710901295ceefde378e9c9967bfdb331456f"

  repository_name  = "${local.project_name}-beta"
  image_source_url = "https://github.com/${local.beta_github_repo_owner}/${local.beta_github_repo_name}"
  common_tags      = local.common_tags

  # Match the alpha app's retention approach (keep last 5 images of any tag
  # status) rather than the module's untagged-only default.
  lifecycle_policy = templatefile(
    "${path.root}/policies/ecr-policies/max-images.json.tpl",
    { max_images = 5 }
  )
}
