data "aws_ssm_parameter" "security_group_main_id" {
    name = "/garage/prod/garage/security_group_main_id"
}

data "aws_ssm_parameter" "private_subnet_id" {
    name = "/garage/prod/garage/private_subnet_id"
}

data "aws_ssm_parameter" "private_subnet_b_id" {
    name = "/garage/prod/garage/private_subnet_b_id"
}

# DNS do Load Balancer criado pelo Kubernetes
data "aws_ssm_parameter" "alb_dns" {
    name = "/garage/prod/garage/alb_dns"
}

data "aws_ssm_parameter" "app_dns_region_id" {
    name = "/garage/prod/garage/app_dns_region_id"
}

# # 2. VPC Link (A ponte entre o API Gateway e rede privada)
# resource "aws_apigatewayv2_vpc_link" "eks" {
#     name               = "${local.projectName}-vpc-link"
#     # Adicionado .value aqui:
#     security_group_ids = [data.aws_ssm_parameter.security_group_main_id.value]
#     subnet_ids         = [
#         data.aws_ssm_parameter.private_subnet_id.value,
#         data.aws_ssm_parameter.private_subnet_b_id.value
#     ]
# }

# 3. API e Integração
resource "aws_apigatewayv2_api" "main" {
    name          = "${local.projectName}-api"
    protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "eks" {
    api_id           = aws_apigatewayv2_api.main.id
    integration_type = "HTTP_PROXY"

    integration_uri = "http://${data.aws_ssm_parameter.alb_dns.value}"

    integration_method      = "ANY"
    payload_format_version  = "1.0"
}

resource "aws_apigatewayv2_route" "eks_proxy" {
    api_id    = aws_apigatewayv2_api.main.id
    route_key = "ANY /{proxy+}"

    target = "integrations/${aws_apigatewayv2_integration.eks.id}"
}

resource "aws_apigatewayv2_stage" "default" {
    api_id      = aws_apigatewayv2_api.main.id
    name        = "$default"
    auto_deploy = true
}
