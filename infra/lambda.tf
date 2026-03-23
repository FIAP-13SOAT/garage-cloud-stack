data "aws_ssm_parameter" "db_endpoint" {
    name = "/garage/prod/db/endpoint"
}

data "aws_ssm_parameter" "db_secret_arn" {
    name = "/garage/prod/db/secret_arn"
}

resource "aws_lambda_function" "login_lambda" {
    function_name = var.lambda_function_name
    package_type  = "Image"

    image_uri = "public.ecr.aws/lambda/provided:al2"

    role = "arn:aws:iam::${var.accountId}:role/LabRole"

    memory_size = 1024
    timeout     = 30

    lifecycle {
        ignore_changes = [
            image_uri
        ]
    }

    vpc_config {
        subnet_ids         = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_b.id]
        security_group_ids = [aws_security_group.lambda.id]
    }

    environment {
        variables = {
            DB_HOST     = data.aws_ssm_parameter.db_endpoint.value
            DB_NAME     = "garage"
            DB_USER     = "postgres"
            DB_PASSWORD = data.aws_ssm_parameter.db_secret_arn.value
            JWT_SECRET  = aws_ssm_parameter.jwt_secret.value
        }
    }
}

resource "aws_lambda_function" "auth_lambda" {
    function_name = var.lambda_auth_validator_function_name
    package_type  = "Image"

    image_uri = "public.ecr.aws/lambda/provided:al2"

    role = "arn:aws:iam::${var.accountId}:role/LabRole"

    memory_size = 1024
    timeout     = 30

    lifecycle {
        ignore_changes = [
            image_uri
        ]
    }

    vpc_config {
        subnet_ids         = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_b.id]
        security_group_ids = [aws_security_group.lambda.id]
    }
}
