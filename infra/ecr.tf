########################################
# ECR (Elastic Container Registry)
########################################

# Repositório para armazenar as imagens Docker da aplicação
resource "aws_ecr_repository" "app" {
    name = "${local.projectName}-app"
    
    image_scanning_configuration {
        scan_on_push = true
    }
    
    image_tag_mutability = "MUTABLE"
}
