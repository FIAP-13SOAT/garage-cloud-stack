resource "aws_ecr_repository" "login_lambda" {
    name = "garage-auth-issuer"

    image_scanning_configuration {
        scan_on_push = true
    }

    image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository" "auth_lambda" {
    name = "garage-auth-validator"

    image_scanning_configuration {
        scan_on_push = true
    }

    image_tag_mutability = "MUTABLE"
}
