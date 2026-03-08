variable "repository_name" {
    description = "Name of the ECR repository"
    type        = string
    default     = "garage-auth-function-erc"
}

variable "authorizer_repository_name" {
    description = "Name of the ECR repository for authorizer"
    type        = string
    default     = "garage-authorizer-function-ecr"
}

variable "lambda_function_name" {
    description = "Name of the lambda ECR repository"
    type        = string
    default     = "garage-auth-function"
}

variable "image_tag" {
    description = "Tag of the ECR image to deploy"
    type        = string
    default     = "latest"
}

variable "eks_service_endpoint" {
    description = "Internal endpoint of the EKS service (LoadBalancer or Service)"
    type        = string
    default     = "garage-api-service.default.svc.cluster.local"
}
