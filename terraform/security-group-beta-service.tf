module "beta_security_group" {
  source = "git::https://github.com/nationalarchives/da-terraform-modules.git//security_group?ref=9ae2710901295ceefde378e9c9967bfdb331456f"

  name        = "${local.project_name}-beta-service"
  description = "Beta Service"
  vpc_id      = aws_vpc.app.id
  common_tags = local.common_tags

  rules = {
    ingress = [
      {
        port              = local.beta_container_port
        description       = "Allow HTTP from ALB"
        security_group_id = aws_security_group.ecs_service_alb.id
      }
    ]
    egress = []
  }
}

resource "aws_security_group_rule" "beta_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.beta_security_group.security_group_id
  description       = "Allow all outbound traffic"
}

# The ALB security group is a plain (non-module) resource owned by the
# existing alpha stack, so its egress rule to Beta is added directly here.
resource "aws_security_group_rule" "ecs_service_alb_beta_container_egress_tcp" {
  description              = "Allow container port tcp egress to beta containers"
  type                     = "egress"
  from_port                = local.beta_container_port
  to_port                  = local.beta_container_port
  protocol                 = "tcp"
  source_security_group_id = module.beta_security_group.security_group_id
  security_group_id        = aws_security_group.ecs_service_alb.id
}
