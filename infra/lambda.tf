data "aws_ecr_image" "lambda_image" {
    repository_name = var.repository_name
    image_tag       = var.image_tag
}

// IAM ROLE - LAMBDA EXECUTION
resource "aws_iam_role" "lambda_exec" {
    name = "${var.lambda_function_name}-exec"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Action    = "sts:AssumeRole",
            Effect    = "Allow",
            Principal = { Service = "lambda.amazonaws.com" }
        }]
    })
}

// IAM POLICY - LAMBDA EXECUTION
resource "aws_iam_role_policy_attachment" "lambda_basic" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// IAM POLICY - VPC ACCESS
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

// IAM POLICY - SECRETS MANAGER
resource "aws_iam_role_policy_attachment" "lambda_secrets" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

// IAM POLICY - ECR READONLY
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# LAMBDA FUNCTION - LOGIN (conecta ao RDS)
resource "aws_lambda_function" "terraform_lambda" {
    function_name = var.lambda_function_name
    package_type  = "Image"
    image_uri     = data.aws_ecr_image.lambda_image.image_uri
    role          = aws_iam_role.lambda_exec.arn
    memory_size   = 1024
    timeout       = 30

    vpc_config {
        subnet_ids         = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_b.id]
        security_group_ids = [aws_security_group.lambda.id]
    }

    environment {
        variables = {
            DB_HOST     = aws_db_instance.postgres.address
            DB_NAME     = aws_db_instance.postgres.db_name
            DB_USER     = aws_db_instance.postgres.username
            DB_PASSWORD = aws_db_instance.postgres.master_user_secret[0].secret_arn
            JWT_SECRET  = aws_ssm_parameter.jwt_secret.value
        }
    }
}

// HTTP API GATEWAY
resource "aws_apigatewayv2_api" "lambda_api" {
    name          = "${var.lambda_function_name}-api-gateway"
    protocol_type = "HTTP"
}

# INTEGRATION (API → LAMBDA)
resource "aws_apigatewayv2_integration" "lambda_integration" {
    api_id                 = aws_apigatewayv2_api.lambda_api.id
    integration_type       = "AWS_PROXY"
    integration_uri        = aws_lambda_function.terraform_lambda.invoke_arn
    payload_format_version = "2.0"
}

# ROUTE - LOGIN (sem autenticação)
resource "aws_apigatewayv2_route" "login_route" {
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "POST /login"
    target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# STAGE (AUTO‑DEPLOY)
resource "aws_apigatewayv2_stage" "live" {
    api_id      = aws_apigatewayv2_api.lambda_api.id
    name        = "$default"
    auto_deploy = true
}


# PERMISSION (API → LAMBDA LOGIN)
resource "aws_lambda_permission" "allow_apigw" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.terraform_lambda.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/POST/login"
}

########################################
# LAMBDA AUTHORIZER
########################################

# IAM ROLE - AUTHORIZER
resource "aws_iam_role" "authorizer_exec" {
    name = "${var.lambda_function_name}-authorizer-exec"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Action    = "sts:AssumeRole",
            Effect    = "Allow",
            Principal = { Service = "lambda.amazonaws.com" }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "authorizer_basic" {
    role       = aws_iam_role.authorizer_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# LAMBDA AUTHORIZER FUNCTION
resource "aws_lambda_function" "authorizer" {
    function_name = "${var.lambda_function_name}-authorizer"
    package_type  = "Image"
    image_uri     = "${data.aws_ecr_image.lambda_image.registry_id}.dkr.ecr.${local.awsRegion}.amazonaws.com/${var.authorizer_repository_name}:${var.image_tag}"
    role          = aws_iam_role.authorizer_exec.arn
    memory_size   = 512
    timeout       = 10

    environment {
        variables = {
            JWT_SECRET = aws_ssm_parameter.jwt_secret.value
        }
    }
}

# API GATEWAY AUTHORIZER
resource "aws_apigatewayv2_authorizer" "jwt_authorizer" {
    api_id           = aws_apigatewayv2_api.lambda_api.id
    authorizer_type  = "REQUEST"
    authorizer_uri   = aws_lambda_function.authorizer.invoke_arn
    identity_sources = ["$request.header.Authorization"]
    name             = "jwt-authorizer"
    authorizer_payload_format_version = "2.0"
    enable_simple_responses = true
}

# PERMISSION (API → AUTHORIZER)
resource "aws_lambda_permission" "allow_apigw_authorizer" {
    statement_id  = "AllowAPIGatewayInvokeAuthorizer"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.authorizer.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.jwt_authorizer.id}"
}

########################################
# VPC LINK → EKS
########################################

# VPC LINK para conectar API Gateway ao EKS
resource "aws_apigatewayv2_vpc_link" "eks_link" {
    name               = "${var.lambda_function_name}-eks-link"
    security_group_ids = [aws_security_group.main.id]
    subnet_ids         = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_b.id]
}

# INTEGRATION (API → EKS via VPC Link)
resource "aws_apigatewayv2_integration" "eks_integration" {
    api_id             = aws_apigatewayv2_api.lambda_api.id
    integration_type   = "HTTP_PROXY"
    integration_method = "ANY"
    integration_uri    = "http://${var.eks_service_endpoint}"
    connection_type    = "VPC_LINK"
    connection_id      = aws_apigatewayv2_vpc_link.eks_link.id
}

# ROUTE - PROTECTED (com autenticação)
resource "aws_apigatewayv2_route" "protected_route" {
    api_id             = aws_apigatewayv2_api.lambda_api.id
    route_key          = "$default"
    target             = "integrations/${aws_apigatewayv2_integration.eks_integration.id}"
    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.jwt_authorizer.id
}
