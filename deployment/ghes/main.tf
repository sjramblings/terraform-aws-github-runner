locals {
  environment = "production"
  aws_region  = "ap-southeast-2"
}

module "runners" {
  source                                  = "../../"
  create_service_linked_role_spot         = true
  aws_region                              = local.aws_region
  vpc_id                                  = module.vpc.vpc_id
  subnet_ids                              = module.vpc.private_subnets
  ghes_url                                = "https://ghes.com"
  enable_organization_runners             = true
  runner_extra_labels                     = "managed"
  runner_enable_workflow_job_labels_check = false
  enable_ssm_on_runners                   = true
  runner_as_root                          = true
  instance_types                          = ["t3.medium", "t3.large"]
  runners_maximum_count                   = 30
  minimum_running_time_in_minutes         = 15
  enable_job_queued_check                 = true
  delay_webhook_event                     = 0
  scale_down_schedule_expression          = "cron(* * * * ? *)"
  enable_ephemeral_runners                = true
  fifo_build_queue                        = false
  prefix                                  = local.environment
  runner_iam_role_managed_policy_arns     = ["arn:aws:iam::1234567891011:policy/ReadOnlyECRRepos"]

  tags = {
    Environment              = "production"
  }

  runner_metadata_options = {
    "http_endpoint" : "enabled",
    "http_put_response_hop_limit" : 1,
    "http_tokens" : "required"
  }

  github_app = {
    key_base64     = data.aws_ssm_parameter.github_app_key_base64_src.value
    id             = data.aws_ssm_parameter.github_app_id.value
    webhook_secret = data.aws_ssm_parameter.github_app_webhook_secret_src.value
  }

  webhook_lambda_zip                = "../../modules/download-lambda/webhook.zip"
  runner_binaries_syncer_lambda_zip = "../../modules/download-lambda/runner-binaries-syncer.zip"
  runners_lambda_zip                = "../../modules/download-lambda/runners.zip"

  runner_binaries_s3_sse_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  runner_egress_rules = [{
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = null
    from_port        = 80
    protocol         = "tcp"
    security_groups  = null
    self             = null
    to_port          = 80
    description      = null
    },
    {
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null
      from_port        = 443
      protocol         = "tcp"
      security_groups  = null
      self             = null
      to_port          = 443
      description      = null
  }]

}
