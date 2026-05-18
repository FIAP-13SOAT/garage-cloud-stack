########################################
# ECR (Elastic Container Registry)
#
# Um repositório por microsserviço. Alinha com os manifestos Kubernetes
# que referenciam <ECR_REGISTRY>/garage-<service>:latest.
########################################

resource "aws_ecr_repository" "services" {
    for_each = local.services

    name = each.key

    image_scanning_configuration {
        scan_on_push = true
    }

    image_tag_mutability = "MUTABLE"
}

output "ecr_registry" {
    description = "Endpoint base do ECR usado pelas pipelines de cada serviço"
    value       = "${var.accountId}.dkr.ecr.${local.awsRegion}.amazonaws.com"
}

output "ecr_repository_urls" {
    description = "URL completa de cada repositório ECR por serviço"
    value       = { for k, v in aws_ecr_repository.services : k => v.repository_url }
}
