module "vpc" {
  source = "../../modules/vpc"

  name_tag                           = "ghesRunners"
  environment_tag                    = local.environment
  aws_region                         = local.aws_region
  enable_flow_log                    = true
  flow_log_cloudwatch_log_group_name = "/vpc/flowlogs/ghes_runners"
  optional_tags = {
    ApplicationService = "ghesRunners"
  }
}
