variable "github_app" {
  description = "GitHub app parameters, see your github app. Ensure the key is the base64-encoded `.pem` file (the output of `base64 app.private-key.pem`, not the content of `private-key.pem`)."
  type = object({
    key_base64     = string
    id             = string
    webhook_secret = string
  })
}

variable "environment" {
  description = "A name that identifies the environment, used as prefix and for tagging."
  type        = string
  default     = null

  validation {
    condition     = var.environment == null
    error_message = "The \"environment\" variable is no longer used. To migrate, set the \"prefix\" variable to the original value of \"environment\" and optionally, add \"Environment\" to the \"tags\" variable map with the same value."
  }
}

variable "prefix" {
  description = "The prefix used for naming resources"
  type        = string
  default     = "github-actions"
}

variable "kms_key_arn" {
  description = "Optional CMK Key ARN to be used for Parameter Store."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags that will be added to created resources. By default resources will be tagged with name and environment."
  type        = map(string)
  default     = {}
}
