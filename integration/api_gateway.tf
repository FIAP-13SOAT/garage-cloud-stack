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

### Roteamento para Route S3 ###
# Client
#   ↓
#api.fiapgarage2026.com
#   ↓
#API Gateway
#   ↓
#VPC Link
#   ↓
#Internal ALB
#   ↓
#Kubernetes

# certificado TLS

# resource "aws_acm_certificate" "api" {
#     domain_name       = "api.${local.dns}"
#     validation_method = "DNS"
# }
#
# # (Custom Domain no API Gateway)
# resource "aws_apigatewayv2_domain_name" "api" {
#     domain_name = "api.${local.dns}"
#
#     domain_name_configuration {
#         certificate_arn = aws_acm_certificate.api.arn
#         endpoint_type   = "REGIONAL"
#         security_policy = "TLS_1_2"
#     }
# }
#
# resource "aws_apigatewayv2_api_mapping" "api" {
#     api_id      = aws_apigatewayv2_api.main.id
#     domain_name = aws_apigatewayv2_domain_name.api.id
#     stage       = aws_apigatewayv2_stage.default.id
# }
#
# # Criar o DNS no Route53
# resource "aws_route53_record" "api" {
#     zone_id = data.aws_ssm_parameter.app_dns_region_id.value
#     name    = "api.${local.dns}"
#     type    = "A"
#
#     alias {
#         name                   = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
#         zone_id                = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].hosted_zone_id
#         evaluate_target_health = false
#     }
# }
