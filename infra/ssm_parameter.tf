resource "aws_ssm_parameter" "db_endpoint" {
    name  = "/garage/prod/db/endpoint"
    type  = "String"
    value = aws_db_instance.postgres.endpoint
}

resource "aws_ssm_parameter" "db_secret_arn" {
    name  = "/garage/prod/db/secret_arn"
    type  = "String"
    value = length(aws_db_instance.postgres.master_user_secret) > 0 ? aws_db_instance.postgres.master_user_secret[0].secret_arn : ""
}

resource "aws_ssm_parameter" "jwt_secret" {
    name  = "/garage/prod/jwt/secret"
    type  = "SecureString"
    value = "change-me-in-production-${random_string.jwt_secret.result}"
}

resource "random_string" "jwt_secret" {
    length  = 32
    special = true
}
