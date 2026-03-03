resource "aws_ssm_parameter" "db_endpoint" {
    name  = "/garage/prod/db/endpoint"
    type  = "String"
    value = aws_db_instance.postgres.endpoint
}
