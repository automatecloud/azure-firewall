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

variable "vnet_name" {
  type    = string
  default = "wiz-vnet"
}

variable "vnet_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "proxy_setup" {
  type    = string
  default = "none"

  validation {
    condition     = contains(["none", "reverse", "forward"], var.proxy_setup)
    error_message = "Allowed values for proxy_setup are:\n\"none\": no proxy. \"reverse\": using an azure firewall. \"forward\": using a simple squid proxy."
  }
}

variable "azure_china" {
  type        = bool
  default     = false
  description = "Set to true if deploying to Azure China Cloud"
}