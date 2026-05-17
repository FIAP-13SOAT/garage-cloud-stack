########################################
# ECR (Elastic Container Registry)
#
# Um repositório por microserviço — permite versionar e escanear imagens
# separadamente. URLs ficam expostas em `ecr_repository_urls` (outputs.tf)
# para que os pipelines de cada serviço façam build/push.
########################################

resource "aws_ecr_repository" "service" {
    for_each = toset(local.services)

    name = "${local.projectName}-${each.key}-service"

    image_scanning_configuration {
        scan_on_push = true
    }

    image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "service" {
    for_each   = aws_ecr_repository.service
    repository = each.value.name

    policy = jsonencode({
        rules = [
            {
                rulePriority = 1
                description  = "Manter apenas as 10 imagens mais recentes"
                selection = {
                    tagStatus   = "any"
                    countType   = "imageCountMoreThan"
                    countNumber = 10
                }
                action = { type = "expire" }
            }
        ]
    })
}
