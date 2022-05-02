variable "vpc_id" {
  description = "The ID of the VPC in which a given resource resides."
}

variable "product" {
  description = "The name of the thing we are deploying, e.g. theone, domainmarket."
}

variable "environment" {
  description = "The environment to deploy to, e.g. staging, production."
  default     = "staging"
}

variable "ci_commit_sha" {
  description = "Used in the naming of the launch configuration."
}

variable "ci_job_id" {
  description = "The CI job number.  Used for naming AWS resources."
}

variable "lb_security_groups" {
  description = "The security groups to which the load balancer belongs."
}

variable "ec2_security_groups" {
  description = "The security groups to which the ec2 instances belong."
  type        = list
}

variable "public_subnets" {
  description = "The subnets in which the public resources belong."
  type        = list
}

variable "private_subnets" {
  description = "The subnets in which the private resources belong."
  type        = list
}

variable "instance_type" {
  description = "The instance type to use, e.g. t3.medium."
}

variable "iam_instance_profile" {
  description = "The IAM role to attach to instances."
}

variable "certificate_arn" {
  description = "The certificate to use for the load balancer."
}

variable "git_branch" {
  description = "The branch to check out the git project from."
}

variable "http_health_check_path" {
  description = "The path for the http healh check."
}

variable "http_health_check_matcher" {
  description = "Comma-separated string of expected http return codes for the http health check."
}

variable "https_health_check_path" {
  description = "The path for the https healh check."
}

variable "https_health_check_matcher" {
  description = "Comma-separated string of expected http return codes for the https health check."
}

variable "http_health_check_port" {
  description = "health check port for http target group"
  type = number
}

variable "https_health_check_port" {
  description = "health check port for https target group"
  type = number
}

variable "health_check_type" {
  description = "Type of check (EC2 or ELB) for autoscaling group to perform against instances."
}

variable "desired_capacity" {
  description = "The number of instances you want to run in this Auto Scaling group."
}

variable "max_size" {
  description = "The maximum number of instances the Auto Scaling group should have at any time."
}

variable "min_size" {
  description = "The minimum number of instances the Auto Scaling group should have at any time."
}

