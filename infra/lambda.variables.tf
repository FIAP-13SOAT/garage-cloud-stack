variable "repository_name" {
    description = "Name of the ECR repository"
    type        = string
    default     = "garage-auth-function-erc"
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
