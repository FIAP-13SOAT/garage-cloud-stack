variable "accountId" {
    description = "AWS Account ID"
    type        = string
}

variable "roleName" {
    description = "AWS Role Name for Terraform to assume"
    type        = string
}


variable "environment" {
    description = "Ambiente (prod, staging, dev)"
    type        = string
    default     = "prod"
}
