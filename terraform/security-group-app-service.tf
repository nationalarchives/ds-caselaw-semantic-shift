resource "aws_security_group" "app" {
  name        = "${local.project_name}-app-service"
  description = "App Service"
  vpc_id      = aws_vpc.app.id
}

resource "aws_security_group_rule" "app_http_ingress" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_service_alb.id
  security_group_id        = aws_security_group.app.id
  description              = "Allow HTTP from ALB"
}

resource "aws_security_group_rule" "app_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
  description       = "Allow all outbound traffic"
}
