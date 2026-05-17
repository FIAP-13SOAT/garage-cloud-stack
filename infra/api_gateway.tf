########################################
# HTTP API GATEWAY
#
# Tokens são emitidos pelo garage-auth-service (EKS) e validados pelo
# próprio API Gateway usando OIDC discovery + JWKS.
#
# O backend é o Ingress NGINX dentro do cluster (ver ingress.tf). O
# listener do NLB criado pelo Helm é descoberto via data sources
# logo abaixo — não precisa mais ser preenchido manualmente.
########################################

resource "aws_apigatewayv2_api" "lambda_api" {
    name          = var.api_name
    protocol_type = "HTTP"

    cors_configuration {
        allow_origins = ["*"]
        allow_methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
        allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key"]
        max_age       = 3600
    }
}

########################################
# DESCOBERTA DO NLB DO INGRESS
########################################

# O Service do Ingress NGINX expõe o hostname do NLB; usamos para
# achar o ARN do load balancer e do listener (porta 80).
data "aws_lb" "ingress" {
    name = split("-", data.kubernetes_service.ingress_lb.status[0].load_balancer[0].ingress[0].hostname)[0]

    depends_on = [helm_release.ingress_nginx]
}

data "aws_lb_listener" "ingress" {
    load_balancer_arn = data.aws_lb.ingress.arn
    port              = 80
}

########################################
# VPC LINK - rota o API Gateway para dentro da VPC onde o EKS roda
########################################

resource "aws_apigatewayv2_vpc_link" "eks_link" {
    name               = "${var.api_name}-eks-link"
    security_group_ids = [aws_security_group.main.id]
    subnet_ids         = [local.private_subnet_ids[0], local.private_subnet_ids[1]]
}

resource "aws_apigatewayv2_integration" "eks_integration" {
    api_id             = aws_apigatewayv2_api.lambda_api.id
    integration_type   = "HTTP_PROXY"
    integration_method = "ANY"

    integration_uri = data.aws_lb_listener.ingress.arn

    connection_type = "VPC_LINK"
    connection_id   = aws_apigatewayv2_vpc_link.eks_link.id
}

########################################
# JWT AUTHORIZER (nativo do HTTP API)
#
# O authorizer baixa o OIDC discovery doc em
#   ${issuer}/.well-known/openid-configuration
# e usa o `jwks_uri` dele para validar assinaturas RS256.
# `issuer` aqui é o próprio API Gateway (onde o auth-service é exposto
# publicamente via /login, /admin/login e /.well-known/*).
########################################

resource "aws_apigatewayv2_authorizer" "jwt" {
    api_id           = aws_apigatewayv2_api.lambda_api.id
    name             = "garage-jwt-authorizer"
    authorizer_type  = "JWT"
    identity_sources = ["$request.header.Authorization"]

    jwt_configuration {
        audience = [var.jwt_audience]
        issuer   = "https://${aws_apigatewayv2_api.lambda_api.id}.execute-api.${local.awsRegion}.amazonaws.com"
    }
}

########################################
# ROTAS PÚBLICAS — auth-service (login, JWKS, OIDC discovery)
########################################

resource "aws_apigatewayv2_route" "public_login" {
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "POST /login"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration.id}"
}

resource "aws_apigatewayv2_route" "public_admin_login" {
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "POST /admin/login"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration.id}"
}

resource "aws_apigatewayv2_route" "public_well_known" {
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "GET /.well-known/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration.id}"
}

resource "aws_apigatewayv2_route" "public_customers_create" {
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "POST /customers"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration.id}"
}

resource "aws_apigatewayv2_route" "public_service_orders" {
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /public/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration.id}"
}

########################################
# ROTAS PROTEGIDAS POR JWT
# Nota: $default com HTTP_PROXY via VPC Link não funciona corretamente no
# HTTP API, então mantemos uma rota por recurso.
########################################

locals {
    protected_routes = {
        customers_list           = "GET /customers"
        customers_proxy          = "ANY /customers/{proxy+}"
        vehicles                 = "ANY /vehicles"
        vehicles_proxy           = "ANY /vehicles/{proxy+}"
        service_orders           = "ANY /service-orders"
        service_orders_proxy     = "ANY /service-orders/{proxy+}"
        service_types            = "ANY /service-types"
        service_types_proxy      = "ANY /service-types/{proxy+}"
        quotes                   = "ANY /quotes"
        quotes_proxy             = "ANY /quotes/{proxy+}"
        payments                 = "ANY /payments/{proxy+}"
        executions               = "ANY /service-orders/{proxy+}/execution"
        stock                    = "ANY /stock"
        stock_proxy              = "ANY /stock/{proxy+}"
        stock_movements          = "ANY /stock-movements"
        stock_movements_proxy    = "ANY /stock-movements/{proxy+}"
        notifications            = "ANY /notifications"
        notifications_proxy      = "ANY /notifications/{proxy+}"
        admin_users              = "ANY /admin/users"
        admin_users_proxy        = "ANY /admin/users/{proxy+}"
    }
}

resource "aws_apigatewayv2_route" "protected" {
    for_each = local.protected_routes

    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = each.value
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration.id}"

    authorization_type = "JWT"
    authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
}

########################################
# STAGE
########################################

resource "aws_apigatewayv2_stage" "live" {
    api_id      = aws_apigatewayv2_api.lambda_api.id
    name        = "$default"
    auto_deploy = true
}
