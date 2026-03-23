########################################
# OUTPUTS
########################################

# Endpoint do cluster EKS para configuração do kubectl
output "kubeconfig" {
    description = "Endpoint do cluster EKS"
    value       = aws_eks_cluster.eks_cluster.endpoint
}

# VPC ID para referência cross-repository
output "vpc_id" {
    description = "VPC ID"
    value       = aws_vpc.main.id
}

# IDs das subnets privadas para o DB Subnet Group
output "private_subnet_ids" {
    description = "Private subnet IDs"
    value       = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_b.id]
}

# Security Group gerenciado do cluster EKS
output "eks_cluster_sg_id" {
    description = "EKS cluster managed security group ID"
    value       = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

# Security Group da Lambda
output "lambda_sg_id" {
    description = "Lambda security group ID"
    value       = aws_security_group.lambda.id
}

# output "ecr_repository_url" {
#     value = data.aws_ecr_image.lambda_image.image_uri
# }
