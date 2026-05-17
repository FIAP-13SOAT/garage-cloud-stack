########################################
# JWT RSA key pair — garage-auth-service
#
# A privada assina os JWTs emitidos pelo auth-service; a pública é exposta
# via JWKS (/.well-known/jwks.json) e consumida pelo JWT Authorizer do
# API Gateway HTTP API.
########################################

resource "tls_private_key" "jwt" {
    algorithm = "RSA"
    rsa_bits  = 2048
}

resource "aws_ssm_parameter" "jwt_private_key" {
    name      = "/${local.projectName}/prod/garage-auth-service/jwt_private_key"
    type      = "SecureString"
    value     = tls_private_key.jwt.private_key_pem
    overwrite = true
}

resource "aws_ssm_parameter" "jwt_public_key" {
    name      = "/${local.projectName}/prod/garage-auth-service/jwt_public_key"
    type      = "String"
    value     = tls_private_key.jwt.public_key_pem
    overwrite = true
}
