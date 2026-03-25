########################################
# SSM PARAMETERS - DB (created by garage-database-infra)
########################################

data "aws_ssm_parameter" "db_endpoint" {
    name = "/garage/prod/db/endpoint"
}

data "aws_ssm_parameter" "db_secret_arn" {
    name = "/garage/prod/db/secret_arn"
}

data "aws_secretsmanager_secret_version" "db_credentials" {
    secret_id = data.aws_ssm_parameter.db_secret_arn.value
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

    depends_on = [
        aws_ecr_repository.login_lambda,
        null_resource.seed_ecr_images
    ]

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
            ENVIRONMENT    = "prod"
            DB_HOST_PROD   = split(":", data.aws_ssm_parameter.db_endpoint.value)[0]
            DB_PORT_PROD   = "5432"
            DB_NAME_PROD   = "garage"
            DB_USER_PROD   = "postgres"
            DB_PASSWORD_PROD = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["password"]
            JWT_SECRET     = aws_ssm_parameter.jwt_secret.value
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

    depends_on = [
        aws_ecr_repository.auth_lambda,
        null_resource.seed_ecr_images
    ]

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
            LAMBDA_MODE  = "validator"
            JWT_SECRET   = aws_ssm_parameter.jwt_secret.value
            ENVIRONMENT  = "prod"
        }
    }
}

########################################
# SEED ECR IMAGES
# Pusha uma imagem placeholder nos ECRs para que as Lambdas possam ser
# criadas no primeiro terraform apply. O pipeline do auth-issuer substitui
# essas imagens pela versão real a cada push na master.
########################################

resource "null_resource" "seed_ecr_images" {
    depends_on = [
        aws_ecr_repository.login_lambda,
        aws_ecr_repository.auth_lambda
    ]

    provisioner "local-exec" {
        command = <<-EOT
            aws ecr get-login-password --region ${local.awsRegion} | docker login --username AWS --password-stdin ${var.accountId}.dkr.ecr.${local.awsRegion}.amazonaws.com

            docker pull public.ecr.aws/lambda/provided:al2023

            docker tag public.ecr.aws/lambda/provided:al2023 ${aws_ecr_repository.login_lambda.repository_url}:latest
            docker push ${aws_ecr_repository.login_lambda.repository_url}:latest

            docker tag public.ecr.aws/lambda/provided:al2023 ${aws_ecr_repository.auth_lambda.repository_url}:latest
            docker push ${aws_ecr_repository.auth_lambda.repository_url}:latest
        EOT
    }
}
