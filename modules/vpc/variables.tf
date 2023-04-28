variable "environment_tag" {
  description = "Mandatory Environment resource tag, used to explicity set Environment tag. Dev,Test,Prod,Production etc."
  type        = string
}

variable "name_tag" {
  description = "Mandatory Name resource tag. Used to explicity set Name tag."
  type        = string
}

variable "project" {
  description = "Project name, will be added for resource tagging."
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "The Amazon region"
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block used for the VPC."
  type        = string
  default     = "192.168.0.0/16"
}

variable "availability_zones" {
  description = "List to specify the availability zones for which subnes will be created. By default all availability zones will be used."
  type        = list(any)
  default     = []
}

variable "create_private_subnets" {
  description = "Indicates to create private subnets."
  type        = bool
  default     = true
}

variable "public_subnet_map_public_ip_on_launch" {
  description = "Enable public ip creaton by default on EC2 instance launch."
  type        = bool
  default     = false
}

variable "create_s3_vpc_endpoint" {
  description = "Whether to create a VPC Endpoint for S3, so the S3 buckets can be used from within the VPC without using the NAT gateway."
  type        = bool
  default     = true
}

variable "optional_tags" {
  description = "Optional resource tags. BillingCustomer, CostCenter, DemandID, OracleProjectCode, OracleProjectTaskID, ServiceOffering"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Map of tags to apply on the public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Map of tags to apply on the private subnets"
  type        = map(string)
  default     = {}
}

variable "enable_create_defaults" {
  description = "Replaces AWS default network ACL, security group and routing table with module resources"
  type        = bool
  default     = true
}

variable "enable_flow_log" {
  description = "Should be true if you want to enable flow log."
  type        = bool
  default     = false
}

variable "flow_log_log_destination" {
  description = "The ARN of the logging destination."
  type        = string
  default     = null
}

variable "flow_log_log_destination_type" {
  description = "The type of the logging destination. Valid values: cloud-watch-logs, s3."
  type        = string
  default     = "cloud-watch-logs"
}

variable "flow_log_traffic_type" {
  description = "The type of traffic to capture. Valid values: ACCEPT,REJECT,ALL."
  type        = string
  default     = "ALL"
}

variable "flow_log_log_format" {
  description = "The fields to include in the flow log record, in the order in which they should appear."
  type        = string
  default     = null
}

variable "flow_log_max_aggregation_interval" {
  description = "The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid Values: 60 seconds (1 minute) or 600 seconds (10 minutes)."
  type        = number
  default     = 600
}

variable "flow_log_cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group. If omitted, Terraform will assign a random, unique name. Conflicts with role_name_prefix. NOTE: Modifying this variable forces replacement."
  type        = string
  default     = null
}

variable "flow_log_cloudwatch_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
  type        = number
  default     = 7
}

variable "flow_log_cloudwatch_role_name" {
  description = "Name of the IAM role. If omitted, Terraform will assign a random, unique name. Conflicts with role_name_prefix. NOTE: Modifying this variable forces replacement."
  type        = string
  default     = null
}

variable "flow_log_cloudwatch_role_description" {
  description = "Description of the IAM role."
  type        = string
  default     = null
}

variable "flow_log_cloudwatch_role_policy_name" {
  description = "Name of the IAM role policy. If omitted, Terraform will assign a random, unique name. Conflicts with role_name_prefix. NOTE: Modifying this variable forces replacement."
  type        = string
  default     = null
}
