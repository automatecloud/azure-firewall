variable "subscription_id" {
  type = string
}

variable "use_existing_resource_group" {
  type    = bool
  default = false
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_region" {
  type = string
}

variable "azure_china" {
  type        = bool
  default     = false
  description = "Set to true if deploying to Azure China Cloud"
}