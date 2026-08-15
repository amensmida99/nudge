variable "project_name" {
  description = "Short name used as a prefix for all resource names."
  type        = string
  default     = "nudge"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod). Used as a naming suffix."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region for all resources."
  type        = string
  default     = "eu-central-1"
}

variable "node_count" {
  description = "Number of nodes in the EKS managed node group."
  type        = number
  default     = 1
}

variable "node_instance_type" {
  description = "Instance type for EKS nodes. t3.small is cheap and fine for a beta workload."
  type        = string
  default     = "t3.small"
}

variable "tags" {
  description = "Extra tags applied to all resources."
  type        = map(string)
  default     = {}
}
