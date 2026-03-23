########################################
# SSM PARAMETERS - DB (created by garage-database-infra)
########################################

data "aws_ssm_parameter" "db_endpoint" {
    name = "/garage/prod/db/endpoint"
}

data "aws_ssm_parameter" "db_secret_arn" {
    name = "/garage/prod/db/secret_arn"
}

########################################
# LAMBDA - Auth Issuer (login)
########################################

resource "aws_lambda_function" "login_lambda" {
    function_name = var.lambda_function_name
    package_type  = "Image"

    image_uri = "${aws_ecr_repository.login_lambda.repository_url}:${var.image_tag}"

    role = "arn:aws:iam::${var.accountId}:role/LabRole"

    memory_size = 1024
    timeout     = 30

    depends_on = [aws_ecr_repository.login_lambda]

    lifecycle {
        ignore_changes = [
            image_uri
        ]
    }

    vpc_config {
        subnet_ids         = [local.private_subnet_ids[0], local.private_subnet_ids[1]]
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

########################################
# LAMBDA - Auth Validator (authorizer)
########################################

resource "aws_lambda_function" "auth_lambda" {
    function_name = var.lambda_auth_validator_function_name
    package_type  = "Image"

    image_uri = "${aws_ecr_repository.auth_lambda.repository_url}:${var.image_tag}"

    role = "arn:aws:iam::${var.accountId}:role/LabRole"

    memory_size = 1024
    timeout     = 30

    depends_on = [aws_ecr_repository.auth_lambda]

    lifecycle {
        ignore_changes = [
            image_uri
        ]
    }

    vpc_config {
        subnet_ids         = [local.private_subnet_ids[0], local.private_subnet_ids[1]]
        security_group_ids = [aws_security_group.lambda.id]
    }
}
