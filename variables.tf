variable "vpc_id" {
  description = "The ID of the VPC in which a given resource resides."
}

variable "product" {
  description = "The name of the thing we are deploying, e.g. theone, domainmarket."
}

variable "environment" {
  description = "The environment to deploy to, e.g. staging, production."
  default = "staging"
}

variable "ci_commit_sha" {
  description = "Used in the naming of the launch configuration."
}

variable "lb_security_groups" {
  description = "The security groups to which the load balancer belongs."
}

variable "ec2_security_groups" {
  description = "The security groups to which the ec2 instances belong."
  type = "list"
}

variable "public_subnets" {
  description = "The subnets in which the public resources belong."
  type = "list"
}

variable "private_subnets" {
  description = "The subnets in which the private resources belong."
  type = "list"
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
