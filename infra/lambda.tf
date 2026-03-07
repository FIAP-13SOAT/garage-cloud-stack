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

// IAM POLICY - ECR READONLY
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# LAMBDA FUNCTION
resource "aws_lambda_function" "terraform_lambda" {
    function_name = var.lambda_function_name
    package_type  = "Image"
    image_uri     = data.aws_ecr_image.lambda_image.image_uri
    role          = aws_iam_role.lambda_exec.arn
    memory_size   = 1024
    timeout       = 30
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

# DEFAULT ROUTE
resource "aws_apigatewayv2_route" "default_route" {
    api_id    = aws_apigatewayv2_api.lambda_api.id
    route_key = "POST /greetings"
    target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# STAGE (AUTO‑DEPLOY)
resource "aws_apigatewayv2_stage" "live" {
    api_id      = aws_apigatewayv2_api.lambda_api.id
    name        = "$default"
    auto_deploy = true
}


# PERMISSION (API → LAMBDA)
resource "aws_lambda_permission" "allow_apigw" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.terraform_lambda.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/POST/greetings"
}
