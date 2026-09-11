resource "aws_codedeploy_app" "beta_blue_green" {
  compute_platform = "ECS"
  name             = "${local.project_name}-beta-b-g"
}

resource "aws_codedeploy_deployment_config" "beta_blue_green" {
  deployment_config_name = "${local.project_name}-beta-b-g"
  compute_platform       = "ECS"

  traffic_routing_config {
    type = "AllAtOnce"
  }
}

resource "aws_codedeploy_deployment_group" "beta_blue_green" {
  app_name = aws_codedeploy_app.beta_blue_green.name
  # Reuses the existing alpha CodeDeploy service role: its policy is fully
  # generic (Resource "*"), so a second identical role is not needed.
  deployment_config_name = aws_codedeploy_deployment_config.beta_blue_green.deployment_config_name
  deployment_group_name  = "${local.project_name}-beta-b-g"
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
    service_name = aws_ecs_service.beta.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [
          aws_alb_listener.ecs_service_http_https.arn
        ]
      }

      target_group {
        name = aws_alb_target_group.beta_green.name
      }

      target_group {
        name = aws_alb_target_group.beta_blue.name
      }
    }
  }
}
