locals {
  webhook_endpoint = "webhook"
  role_path        = var.role_path == null ? "/${var.prefix}/" : var.role_path
  lambda_zip       = var.lambda_zip == null ? "${path.module}/lambdas/webhook/webhook.zip" : var.lambda_zip
}

resource "aws_api_gateway_rest_api" "webhook" {
  name = "webhook"

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = ["vpce-000000000000"]
  }
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowInvokeWebhook"
  action        = "lambda:InvokeFunction"
  function_name = "${var.prefix}-webhook"
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.webhook.execution_arn}/*/*/*"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.webhook.id
  resource_id   = aws_api_gateway_rest_api.webhook.root_resource_id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.webhook.id
  resource_id             = aws_api_gateway_rest_api.webhook.root_resource_id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.webhook.invoke_arn
}

resource "aws_api_gateway_deployment" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.webhook.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.webhook.root_resource_id,
      aws_api_gateway_method.method.id,
      aws_api_gateway_integration.integration.id,
      aws_api_gateway_rest_api_policy.webhook.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_rest_api_policy.webhook
  ]
}

resource "aws_api_gateway_stage" "webhook" {
  deployment_id        = aws_api_gateway_deployment.webhook.id
  rest_api_id          = aws_api_gateway_rest_api.webhook.id
  stage_name           = "webhook"
  xray_tracing_enabled = true
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.webhook.id
  stage_name  = aws_api_gateway_stage.webhook.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = false
    logging_level   = "INFO"
  }

  depends_on = [
    aws_api_gateway_account.webhook
  ]
}

resource "aws_api_gateway_rest_api_policy" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.webhook.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "${aws_api_gateway_rest_api.webhook.execution_arn}/*",
      "Condition" : {
          "IpAddress": {
              "aws:SourceIp": ["10.0.0.0/8" ]
          }
      }
    }
  ]
}
EOF
}

resource "aws_api_gateway_account" "webhook" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_iam_role" "cloudwatch" {

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  role = aws_iam_role.cloudwatch.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}