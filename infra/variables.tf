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

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "node_count" {
  description = "Number of nodes in the AKS system node pool."
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "VM size for AKS nodes. Standard_B2s is cheap and fine for a beta workload."
  type        = string
  default     = "Standard_B2s"
}

variable "tags" {
  description = "Extra tags applied to all resources."
  type        = map(string)
  default     = {}
}
