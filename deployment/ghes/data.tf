data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "github_app_key_base64_src" {
  name = "/actions_runner/production/github_app_key_base64_src"
}

data "aws_ssm_parameter" "github_app_id" {
  name = "/actions_runner/production/github_app_id_src"
}

data "aws_ssm_parameter" "github_app_webhook_secret_src" {
  name = "/actions_runner/production/github_app_webhook_secret_src"
}

data "aws_ssm_parameter" "github_repo_pat" {
  name = "/actions_runner/production/repo-pat"
}

