resource "aws_vpc" "app" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"

  tags = {
    Name = "${local.project_name}-app"
  }
}

resource "aws_route_table" "app_public" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "${local.project_name}-app-public"
  }
}

resource "aws_internet_gateway" "app_public" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "${local.project_name}-app-public"
  }
}

resource "aws_route" "app_public_internet_gateway" {
  route_table_id         = aws_route_table.app_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.app_public.id
}

resource "aws_subnet" "app_public_a" {
  vpc_id            = aws_vpc.app.id
  availability_zone = "${local.aws_region}a"

  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "${local.project_name}-app-public-a"
  }
}

resource "aws_route_table_association" "infrastructure_public" {
  subnet_id      = aws_subnet.app_public_a.id
  route_table_id = aws_route_table.app_public.id
}
