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

output "api_gateway_url" {
    description = "URL base do API Gateway — usada como JWT issuer no garage-auth-service"
    value       = "https://${aws_apigatewayv2_api.lambda_api.id}.execute-api.${local.awsRegion}.amazonaws.com"
}

output "rabbitmq_endpoint" {
    description = "Endpoint AMQPS do broker RabbitMQ (AWS MQ)"
    value       = aws_mq_broker.rabbitmq.instances[0].endpoints[0]
}
