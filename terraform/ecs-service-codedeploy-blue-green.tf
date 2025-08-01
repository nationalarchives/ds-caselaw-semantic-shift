resource "aws_codedeploy_app" "ecs_service_blue_green" {
  compute_platform = "ECS"
  name             = "${local.project_name}-ecs-service-b-g"
}

resource "aws_codedeploy_deployment_config" "ecs_service_blue_green" {
  deployment_config_name = "${local.project_name}-ecs-service-b-g"
  compute_platform       = "ECS"

  traffic_routing_config {
    type = "AllAtOnce"
  }
}

resource "aws_iam_role" "ecs_service_blue_green_codedeploy" {
  name        = "${local.project_name}-${substr(sha512("ecs-service-blue-green-codedeploy"), 0, 6)}"
  description = "${local.project_name}-ecs-service-blue-green-codedeploy"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["codedeploy.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "ecs_service_blue_green_codedeploy" {
  name        = "${local.project_name}-${substr(sha512("ecs-service-blue-green-codedeploy"), 0, 6)}"
  description = "${local.project_name}-ecs-service-blue-green-codedeploy"
  policy      = templatefile("${path.root}/policies/ecs-codedeploy.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "ecs_service_blue_green_codedeploy" {
  role       = aws_iam_role.ecs_service_blue_green_codedeploy.name
  policy_arn = aws_iam_policy.ecs_service_blue_green_codedeploy.arn
}

resource "aws_codedeploy_deployment_group" "ecs_service_blue_green" {
  app_name               = aws_codedeploy_app.ecs_service_blue_green.name
  deployment_config_name = aws_codedeploy_deployment_config.ecs_service_blue_green.deployment_config_name
  deployment_group_name  = "${local.project_name}-ecs-service-b-g"
  service_role_arn       = aws_iam_role.ecs_service_blue_green_codedeploy.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.app.name
    service_name = aws_ecs_service.app.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [
          aws_alb_listener.ecs_service_http_https.arn
        ]
      }

      target_group {
        name = aws_alb_target_group.ecs_service_green.name
      }

      target_group {
        name = aws_alb_target_group.ecs_service_blue.name
      }
    }
  }
}

resource "terraform_data" "ecs_service_blue_green_create_codedeploy_deployment" {
  triggers_replace = [
    sha256(templatefile(
      "${path.root}/appspecs/ecs.json.tpl",
      {
        task_definition_arn = aws_ecs_task_definition.app.arn
        container_port      = 80
        container_name      = "app"
      }
    )),
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOF
    ${path.root}/local-exec-scripts/create-codedeploy-deployment.sh \
      -a "${aws_codedeploy_app.ecs_service_blue_green.name}" \
      -g "${aws_codedeploy_deployment_group.ecs_service_blue_green.deployment_group_name}" \
      -A "${replace(templatefile(
    "${path.root}/appspecs/ecs.json.tpl",
    {
      task_definition_arn = aws_ecs_task_definition.app.arn
      container_port      = 80
      container_name      = "app"
    }), "\"", "\\\"")}" \
      -S "${sha256(templatefile(
    "${path.root}/appspecs/ecs.json.tpl",
    {
      task_definition_arn = aws_ecs_task_definition.app.arn
      container_port      = 80
      container_name      = "app"
}))}"
    EOF
}

depends_on = [
  aws_codepipeline.app_build,
]
}
