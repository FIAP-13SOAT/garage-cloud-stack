########################################
# OUTPUTS
########################################

output "kubeconfig" {
    description = "Endpoint do cluster EKS"
    value       = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_cluster_sg_id" {
    description = "EKS cluster managed security group ID"
    value       = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

output "lambda_sg_id" {
    description = "Lambda security group ID"
    value       = aws_security_group.lambda.id
}
