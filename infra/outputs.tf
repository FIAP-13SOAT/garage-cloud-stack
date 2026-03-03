########################################
# OUTPUTS
########################################

# Endpoint do cluster EKS para configuração do kubectl
output "kubeconfig" {
    description = "Endpoint do cluster EKS"
    value       = aws_eks_cluster.eks_cluster.endpoint
}

# Endpoint do banco RDS para conexão da aplicação
output "rds_endpoint" {
    description = "Endpoint do banco PostgreSQL"
    value       = aws_db_instance.postgres.endpoint
}

# Porta do banco RDS
output "rds_port" {
    description = "Porta do banco PostgreSQL"
    value       = aws_db_instance.postgres.port
}

# ARN do secret com a senha do banco
output "db_secret_arn" {
    description = "ARN do secret contendo a senha do banco PostgreSQL"
    value       = length(aws_db_instance.postgres.master_user_secret) > 0 ? aws_db_instance.postgres.master_user_secret[0].secret_arn : ""
}
