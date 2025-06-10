resource "aws_ecs_cluster" "app" {
  name = "${local.project_name}-app"
}
