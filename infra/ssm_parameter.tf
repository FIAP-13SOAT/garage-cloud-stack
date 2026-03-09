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

resource "aws_ssm_parameter" "garage_eks_arn" {
    name = "/garage/prod/garage/garage_eks_arn"
    type = "String"
}

resource "aws_ssm_parameter" "security_group_main_id" {
    name  = "/garage/prod/garage/security_group_main_id"
    type  = "String"
    value = aws_security_group.main.id
}

resource "aws_ssm_parameter" "private_subnet_id" {
    name  = "/garage/prod/garage/private_subnet_id"
    type  = "String"
    value = aws_subnet.private_subnet.id
}

resource "aws_ssm_parameter" "private_subnet_b_id" {
    name  = "/garage/prod/garage/private_subnet_id"
    type  = "String"
    value = aws_subnet.private_subnet_b.id
}

resource "aws_ssm_parameter" "alb_dns" {
    name  = "/garage/prod/garage/alb_dns"
    type  = "String"
}
