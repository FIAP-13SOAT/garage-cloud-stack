########################################
# SECURITY GROUPS
########################################

# Security Group do RDS - controla acesso ao banco de dados
resource "aws_security_group" "rds" {
    name_prefix = "${local.projectName}-rds-sg"
    vpc_id      = aws_vpc.main.id

    tags = {
        name = "${local.projectName}-rds-security-group"
    }
}

# Regra separada para evitar dependência cíclica e garantir clareza
resource "aws_security_group_rule" "rds_ingress_eks" {
    type                     = "ingress"
    from_port                = 5432
    to_port                  = 5432
    protocol                 = "tcp"
    security_group_id        = aws_security_group.rds.id

    # Permite acesso do EKS ao RDS usando o security group gerenciado pelo cluster
    # Evita dependência cíclica entre recursos
    source_security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id

    description = "Allow EKS Nodes to access RDS"
}

# Permite Lambda acessar RDS
resource "aws_security_group_rule" "rds_ingress_lambda" {
    type                     = "ingress"
    from_port                = 5432
    to_port                  = 5432
    protocol                 = "tcp"
    security_group_id        = aws_security_group.rds.id
    source_security_group_id = aws_security_group.lambda.id
    description              = "Allow Lambda to access RDS"
}

# Security Group para o EKS cluster - controla tráfego de rede
resource "aws_security_group" "main" {
    name_prefix = "${local.projectName}-eks-sg"
    vpc_id      = aws_vpc.main.id

    # Permite comunicação interna com API Server do EKS e outros componentes do cluster
    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    # Libera comunicação entre os próprios nodes (kubectl logs, exec, etc)
    ingress {
        from_port = 10250
        to_port   = 10250
        protocol  = "tcp"
        self      = true
    }

    # Permite API Gateway acessar EKS via VPC Link
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        name = "${local.projectName}-eks-security-group"
    }
}

# Security Group para Lambda
resource "aws_security_group" "lambda" {
    name_prefix = "${local.projectName}-lambda-sg"
    vpc_id      = aws_vpc.main.id

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        name = "${local.projectName}-lambda-security-group"
    }
}
