variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region in which resources will be provisioned. Example: us-east-1"
}

variable "vpc_id" {
  type        = string
  description = "The AWS VPC that provisioned resources will be associated with"
}

variable "subnet_a_id" {
  type        = string
  description = "First public subnet"
}

variable "subnet_b_id" {
  type        = string
  description = "Second public subnet"
}

variable "web_ecs_task_image_version" {
  type        = string
  description = "Tag/version of the docker image run as the web ecs task"
}

variable "web_ecs_task_desired_count" {
  type        = number
  description = "Amount of web ecs tasks desired to be running at any point in time"
}

variable "web_ecs_task_max_pct" {
  type        = number
  description = "Maximum percentage of web ecs tasks desired to be running during a deployment"
}

variable "web_ecs_task_min_pct" {
  type        = number
  description = "Minimum percentage of web ecs tasks desired to be running during a deployment"
}

variable "web_ecs_task_log_retention_days" {
  type        = number
  description = "Number of days to retain logs written to the web ecs Cloudwatch log group"
}
