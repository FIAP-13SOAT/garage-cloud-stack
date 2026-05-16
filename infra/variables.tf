variable "accountId" {
    description = "AWS Account ID"
    type        = string
}

variable "roleName" {
    description = "IAM Role name for EKS access"
    type        = string
}

variable "api_name" {
    description = "Name of the HTTP API Gateway"
    type        = string
    default     = "garage-api"
}

variable "jwt_audience" {
    description = "Expected 'aud' claim in the JWT — emitido pelo garage-auth-service"
    type        = string
    default     = "garage-api"
}

variable "eks_lb_listener_arn" {
    description = "ARN do listener do Load Balancer interno do EKS (preenchido pelo deploy do garage-os-service)"
    type        = string
    default     = ""
}
