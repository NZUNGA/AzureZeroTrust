variable "resource_group_name" {
  description = "Name of the main resource group"
  type        = string
  default     = "rg-zerotrust-dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "canadacentral"
}

variable "environment" {
  description = "Environment tag value"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Short project name used in resource naming"
  type        = string
  default     = "zerotrust"
}

variable "owner" {
  description = "Owner tag"
  type        = string
  default     = "gael.nzunga"
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
  default     = "IT-SECURITY"
}

variable "vnet_address_space" {
  type    = string
  default = "10.10.0.0/16"
}

variable "subnet_app_prefix" {
  type    = string
  default = "10.10.1.0/24"
}

variable "subnet_pe_prefix" {
  type    = string
  default = "10.10.2.0/24"
}

variable "subnet_bastion_prefix" {
  description = "Must be minimum /26"
  type        = string
  default     = "10.10.3.0/26"
}

variable "subnet_firewall_prefix" {
  description = "Must be minimum /26"
  type        = string
  default     = "10.10.4.0/26"
}

variable "sql_aad_admin_login" {
  description = "Display name of the Entra ID SQL admin"
  type        = string
}

variable "sql_aad_admin_object_id" {
  description = "Object ID of the Entra ID SQL admin"
  type        = string
  sensitive   = true
}