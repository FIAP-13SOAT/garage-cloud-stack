########################################
# OUTPUTS
########################################

output "cluster_endpoint" {
    description = "Endpoint do cluster EKS"
    value       = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_name" {
    description = "Nome do cluster EKS — usado em `aws eks update-kubeconfig`"
    value       = aws_eks_cluster.eks_cluster.name
}

output "eks_cluster_sg_id" {
    description = "EKS cluster managed security group ID"
    value       = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

output "lambda_sg_id" {
    description = "Lambda security group ID"
    value       = aws_security_group.lambda.id
}

output "ecr_repository_urls" {
    description = "URL do repositório ECR de cada microserviço (consumido pelos pipelines de build/push)"
    value = {
        for svc in local.services :
        svc => aws_ecr_repository.service[svc].repository_url
    }
}

output "namespaces" {
    description = "Namespaces Kubernetes provisionados"
    value = merge(
        { for svc in local.services : svc => kubernetes_namespace.service[svc].metadata[0].name },
        { shared = kubernetes_namespace.shared.metadata[0].name }
    )
}

output "ingress_lb_hostname" {
    description = "Hostname do NLB interno criado pelo Ingress NGINX — alvo do VPC Link do API Gateway"
    value       = data.kubernetes_service.ingress_lb.status[0].load_balancer[0].ingress[0].hostname
}

output "ingress_lb_listener_arn" {
    description = "ARN do listener (porta 80) do NLB do Ingress — agora descoberto via data source"
    value       = data.aws_lb_listener.ingress.arn
}

output "api_gateway_endpoint" {
    description = "Endpoint público do HTTP API Gateway"
    value       = aws_apigatewayv2_api.lambda_api.api_endpoint
}

output "rabbitmq_url" {
    description = "URL AMQP interna do RabbitMQ — consumida pelos serviços via secret por namespace"
    value       = local.rabbitmq_url
    sensitive   = true
}
