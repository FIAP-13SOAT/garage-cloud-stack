resource "aws_apigatewayv2_api" "lambda_api" {
    name          = "${var.lambda_function_name}-api"
    protocol_type = "HTTP"
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

resource "aws_lambda_permission" "allow_login" {
    statement_id  = "AllowAPIGatewayInvokeLogin"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.login_lambda.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_authorizer" "jwt_authorizer" {
    api_id = aws_apigatewayv2_api.lambda_api.id
    name   = "jwt-authorizer"

    authorizer_type = "JWT"

    identity_sources = ["$request.header.Authorization"]

    jwt_configuration {
        issuer   = "https://api.fiapchallenge.com"
        audience = ["my-api"]
    }
}

resource "aws_apigatewayv2_vpc_link" "eks_link" {
    name               = "${var.lambda_function_name}-eks-link"
    security_group_ids = [aws_security_group.main.id]
    subnet_ids         = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_b.id]
}

resource "aws_apigatewayv2_integration" "eks_integration" {
    api_id             = aws_apigatewayv2_api.lambda_api.id
    integration_type   = "HTTP_PROXY"
    integration_method = "ANY"

    integration_uri = "http://${var.eks_service_endpoint}"

    connection_type = "VPC_LINK"
    connection_id   = aws_apigatewayv2_vpc_link.eks_link.id
}

resource "aws_apigatewayv2_route" "protected" {
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "$default"

    target = "integrations/${aws_apigatewayv2_integration.eks_integration.id}"

    authorization_type = "JWT"
    authorizer_id      = aws_apigatewayv2_authorizer.jwt_authorizer.id
}

resource "aws_apigatewayv2_stage" "live" {
    api_id      = aws_apigatewayv2_api.lambda_api.id
    name        = "$default"
    auto_deploy = true
}
