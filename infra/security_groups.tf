########################################
# SECURITY GROUPS
########################################

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
