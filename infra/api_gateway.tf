resource "aws_apigatewayv2_api" "lambda_api" {
    name          = "${var.lambda_function_name}-api"
    protocol_type = "HTTP"

    cors_configuration {
        allow_origins = ["*"]
        allow_methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
        allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key"]
        max_age       = 3600
    }
}

resource "aws_apigatewayv2_integration" "lambda_login" {
    api_id                 = aws_apigatewayv2_api.lambda_api.id
    integration_type       = "AWS_PROXY"
    integration_uri        = aws_lambda_function.login_lambda.invoke_arn
    payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "login_route" {
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "POST /login"
    target    = "integrations/${aws_apigatewayv2_integration.lambda_login.id}"
}

resource "aws_apigatewayv2_route" "admin_login_route" {
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "POST /admin/login"
    target    = "integrations/${aws_apigatewayv2_integration.lambda_login.id}"
}

resource "aws_lambda_permission" "allow_login" {
    statement_id  = "AllowAPIGatewayInvokeLogin"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.login_lambda.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}

# Autorizador do tipo REQUEST
resource "aws_apigatewayv2_authorizer" "lambda_authorizer" {
    api_id           = aws_apigatewayv2_api.lambda_api.id
    name             = "custom-lambda-authorizer"
    authorizer_type  = "REQUEST"

    authorizer_uri   = aws_lambda_function.auth_lambda.invoke_arn

    identity_sources = ["$request.header.Authorization"]
    authorizer_payload_format_version = "2.0"
    enable_simple_responses           = true
}

# Rota pública para criar customers (sem autenticação)
resource "aws_apigatewayv2_route" "public_customers" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "POST /customers"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"
}

# ============================================================
# Rotas públicas para Swagger UI e OpenAPI docs (sem autenticação)
# ============================================================

resource "aws_apigatewayv2_route" "swagger_ui" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "GET /swagger-ui/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"
}

resource "aws_apigatewayv2_route" "swagger_ui_html" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "GET /swagger-ui.html"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"
}

resource "aws_apigatewayv2_route" "api_docs" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "GET /v3/api-docs"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"
}

resource "aws_apigatewayv2_route" "api_docs_proxy" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "GET /v3/api-docs/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"
}

resource "aws_apigatewayv2_route" "public_root" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "GET /"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"
}

resource "aws_apigatewayv2_route" "public_robots" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "GET /robots.txt"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"
}

# ============================================================
# Rotas protegidas por recurso (com Lambda Authorizer)
# Nota: $default com HTTP_PROXY via VPC Link não funciona
# corretamente no API Gateway HTTP API, então usamos rotas
# específicas com {proxy+} para cada recurso.
# ============================================================

resource "aws_apigatewayv2_route" "protected_customers_get" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "GET /customers"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_customers_proxy" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /customers/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_vehicles" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /vehicles/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_vehicles_root" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /vehicles"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_service_orders" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /service-orders"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_service_orders_proxy" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /service-orders/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_service_types" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /service-types"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_service_types_proxy" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /service-types/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_quotes" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /quotes/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_users" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /users"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_users_proxy" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /users/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_stock" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /stock"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_stock_proxy" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /stock/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_stock_movements" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /stock-movements"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_stock_movements_proxy" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /stock-movements/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_reports" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /reports"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_reports_proxy" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /reports/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_notifications" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /notifications"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "protected_notifications_proxy" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /notifications/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"

    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

resource "aws_apigatewayv2_route" "public_service_orders" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "ANY /public/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"
}

resource "aws_apigatewayv2_route" "public_actuator" {
    count     = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "GET /actuator/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.eks_integration[0].id}"
}

resource "aws_lambda_permission" "allow_authorizer" {
    statement_id  = "AllowAPIGatewayInvokeAuthorizer"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.auth_lambda.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.lambda_authorizer.id}"
}

variable "eks_lb_listener_arn" {
    description = "ARN do listener do Load Balancer interno do EKS"
    type        = string
    default     = ""
}

resource "aws_apigatewayv2_vpc_link" "eks_link" {
    count              = var.eks_lb_listener_arn != "" ? 1 : 0
    name               = "${var.lambda_function_name}-eks-link"
    security_group_ids = [aws_security_group.main.id]
    subnet_ids         = [local.private_subnet_ids[0], local.private_subnet_ids[1]]
}

resource "aws_apigatewayv2_integration" "eks_integration" {
    count              = var.eks_lb_listener_arn != "" ? 1 : 0
    api_id             = aws_apigatewayv2_api.lambda_api.id
    integration_type   = "HTTP_PROXY"
    integration_method = "ANY"

    integration_uri    = var.eks_lb_listener_arn

    connection_type = "VPC_LINK"
    connection_id   = aws_apigatewayv2_vpc_link.eks_link[0].id
}

resource "aws_apigatewayv2_stage" "live" {
    api_id      = aws_apigatewayv2_api.lambda_api.id
    name        = "$default"
    auto_deploy = true
}
