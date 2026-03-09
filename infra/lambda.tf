data "aws_ecr_image" "lambda_image" {
    repository_name = var.repository_name
    image_tag       = var.image_tag
}

resource "aws_lambda_function" "login_lambda" {
    function_name = var.lambda_function_name
    package_type  = "Image"
    image_uri     = data.aws_ecr_image.lambda_image.image_uri
    role          = "arn:aws:iam::${var.accountId}:role/LabRole"

    memory_size = 1024
    timeout     = 30

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
