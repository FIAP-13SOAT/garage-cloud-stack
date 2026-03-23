resource "aws_ssm_parameter" "jwt_secret" {
    name  = "/garage/prod/jwt/secret"
    type  = "SecureString"
    value = "change-me-in-production-${random_string.jwt_secret.result}"
}

resource "random_string" "jwt_secret" {
    length  = 32
    special = true
}
