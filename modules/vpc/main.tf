data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az              = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available.names
  name_tag        = var.name_tag != null ? tomap({ "Name" = var.name_tag }) : null
  environment_tag = var.environment_tag != null ? tomap({ "environment_tag" = var.environment_tag }) : null
}

resource "aws_vpc" "vpc" {
  cidr_block           = cidrsubnet(var.cidr_block, 0, 0)
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    local.name_tag,
    local.environment_tag,
    var.optional_tags,
  )
}

resource "aws_default_network_acl" "default" {
  count = var.enable_create_defaults ? 1 : 0

  default_network_acl_id = aws_vpc.vpc.default_network_acl_id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    local.name_tag,
    local.environment_tag,
    var.optional_tags,
  )

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

resource "aws_default_route_table" "route_table" {
  count = var.enable_create_defaults ? 1 : 0

  default_route_table_id = aws_vpc.vpc.default_route_table_id

  tags = merge(
    local.name_tag,
    local.environment_tag,
    var.optional_tags,
  )
}

resource "aws_default_security_group" "default" {
  count = var.enable_create_defaults ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.name_tag,
    local.environment_tag,
    var.optional_tags,
  )
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.name_tag,
    local.environment_tag,
    var.optional_tags,
  )
}

resource "aws_route_table" "public_routetable" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.name_tag,
    local.environment_tag,
    var.optional_tags,
  )
}

resource "aws_route" "public_route" {
  depends_on = [aws_route_table.public_routetable]

  route_table_id         = aws_route_table.public_routetable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  availability_zone       = element(local.az, count.index)
  map_public_ip_on_launch = var.public_subnet_map_public_ip_on_launch
  count                   = length(local.az)

  tags = merge(
    {
      "Name" = format(
        "%s-%s-public",
        var.environment_tag,
        element(local.az, count.index),
      )
    },
    {
      "Tier" = "public"
    },
    var.public_subnet_tags
  )
}

resource "aws_route_table_association" "public_routing_table" {
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_routetable.id
  count          = length(local.az)
}

resource "aws_route_table" "private_routetable" {
  count  = var.create_private_subnets ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.name_tag,
    local.environment_tag,
    var.optional_tags,
  )
}

resource "aws_route" "private_route" {
  count      = var.create_private_subnets ? 1 : 0
  depends_on = [aws_route_table.private_routetable]

  route_table_id         = element(aws_route_table.private_routetable.*.id, 0)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat.*.id, 0)
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = cidrsubnet(
    var.cidr_block,
    8,
    length(local.az) + count.index,
  )

  availability_zone       = element(local.az, count.index)
  map_public_ip_on_launch = false
  count                   = var.create_private_subnets ? length(local.az) : 0

  tags = merge(
    {
      "Name" = format(
        "%s-%s-private",
        var.environment_tag,
        element(local.az, count.index),
      )
    },
    {
      "Tier" = "private"
    },
    var.private_subnet_tags
  )
}

resource "aws_route_table_association" "private_routing_table" {
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.private_routetable.*.id, 0)
  count          = var.create_private_subnets ? length(local.az) : 0
}

data "aws_vpc_endpoint_service" "s3" {
  count        = var.create_s3_vpc_endpoint ? 1 : 0
  service      = "s3"
  service_type = "Gateway"
}

resource "aws_vpc_endpoint" "s3_vpc_endpoint" {
  count        = var.create_s3_vpc_endpoint ? 1 : 0
  vpc_id       = aws_vpc.vpc.id
  service_name = element(data.aws_vpc_endpoint_service.s3.*.service_name, 0)
  tags = merge(
    local.name_tag,
    local.environment_tag,
    var.optional_tags,
  )
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count = var.create_s3_vpc_endpoint && var.create_private_subnets ? 1 : 0

  vpc_endpoint_id = element(aws_vpc_endpoint.s3_vpc_endpoint.*.id, 0)
  route_table_id  = element(aws_route_table.private_routetable.*.id, count.index)
}

resource "aws_vpc_endpoint_route_table_association" "public_s3" {
  count = var.create_s3_vpc_endpoint ? 1 : 0

  vpc_endpoint_id = element(aws_vpc_endpoint.s3_vpc_endpoint.*.id, 0)
  route_table_id  = element(aws_route_table.public_routetable.*.id, count.index)
}

resource "aws_eip" "nat" {
  count = var.create_private_subnets ? 1 : 0
  vpc   = true

  tags = merge(
    local.name_tag,
    local.environment_tag,
    var.optional_tags,
  )
}

resource "aws_nat_gateway" "nat" {
  count         = var.create_private_subnets ? 1 : 0
  allocation_id = element(aws_eip.nat.*.id, 0)
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = merge(
    local.name_tag,
    local.environment_tag,
    var.optional_tags,
  )
}

resource "aws_flow_log" "vpc_flow_log" {
  count = var.enable_flow_log ? 1 : 0

  vpc_id                   = aws_vpc.vpc.id
  log_destination_type     = var.flow_log_log_destination_type
  log_destination          = var.flow_log_log_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.cloudwatch_log_group_flow_log[0].arn : var.flow_log_log_destination
  iam_role_arn             = var.flow_log_log_destination_type == "cloud-watch-logs" ? aws_iam_role.iam_role_flow_log[0].arn : null
  traffic_type             = var.flow_log_traffic_type
  log_format               = var.flow_log_log_format
  max_aggregation_interval = var.flow_log_max_aggregation_interval

  tags = merge(
    local.name_tag,
    local.environment_tag,
    var.optional_tags,
  )
}

resource "aws_cloudwatch_log_group" "cloudwatch_log_group_flow_log" {
  count = var.enable_flow_log && var.flow_log_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name              = var.flow_log_cloudwatch_log_group_name
  retention_in_days = var.flow_log_cloudwatch_retention_in_days

  tags = merge(
    local.name_tag,
    local.environment_tag,
    var.optional_tags,
  )
}

resource "aws_iam_role" "iam_role_flow_log" {
  count = var.enable_flow_log && var.flow_log_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name        = var.flow_log_cloudwatch_role_name
  description = var.flow_log_cloudwatch_role_description

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "iam_role_policy_flow_log" {
  count = var.enable_flow_log && var.flow_log_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name = var.flow_log_cloudwatch_role_policy_name
  role = aws_iam_role.iam_role_flow_log[0].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
    ],
      "Resource": "${aws_cloudwatch_log_group.cloudwatch_log_group_flow_log[0].arn}:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}
