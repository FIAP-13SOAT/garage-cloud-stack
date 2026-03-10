# data "aws_ssm_parameter" "security_group_main_id" {
#     name = "/garage/prod/garage/security_group_main_id"
# }
#
# data "aws_ssm_parameter" "private_subnet_id" {
#     name = "/garage/prod/garage/private_subnet_id"
# }
#
# data "aws_ssm_parameter" "private_subnet_b_id" {
#     name = "/garage/prod/garage/private_subnet_b_id"
# }
#
# # DNS do Load Balancer criado pelo Kubernetes
# data "aws_ssm_parameter" "alb_dns" {
#     name = "/garage/prod/garage/alb_dns"
# }

# 2. VPC Link (A ponte entre o API Gateway e rede privada)
resource "aws_apigatewayv2_vpc_link" "eks" {
    name               = "${local.projectName}-vpc-link"
    # Adicionado .value aqui:
    security_group_ids = [aws_security_group.main.id]
    subnet_ids         = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_b.id]
}

# 3. API e Integração
resource "aws_apigatewayv2_api" "main" {
    name          = "${local.projectName}-api"
    protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "eks" {
    api_id             = aws_apigatewayv2_api.main.id
    integration_type   = "HTTP_PROXY"

    # IMPORTANTE: Aqui vai o DNS do Load Balancer, não o ARN do EKS
    integration_uri    = aws_lb_listener.http.arn

    integration_method = "ANY"
    connection_type    = "VPC_LINK"
    connection_id      = aws_apigatewayv2_vpc_link.eks.id
}
