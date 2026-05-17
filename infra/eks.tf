########################################
# KUBERNETES (EKS)
########################################

# Cluster Kubernetes (EKS) na AWS para orquestrar a aplicação
# Usando LabRole pois AWS Academy não permite criação de IAM Roles customizadas
resource "aws_eks_cluster" "eks_cluster" {
    name = "${local.projectName}-cluster"
    role_arn = "arn:aws:iam::${var.accountId}:role/LabRole"

    vpc_config {
        subnet_ids = [
            local.private_subnet_ids[0],
            local.private_subnet_ids[1]
        ]
        security_group_ids = [
            aws_security_group.main.id
        ]
        endpoint_public_access  = true
        endpoint_private_access = false
    }

    access_config {
        authentication_mode = "API_AND_CONFIG_MAP"
    }

    depends_on = [
        # Removido dependência de roles criadas
    ]
}

# Node Groups: Instâncias EC2 que executam os workloads do Kubernetes
resource "aws_eks_node_group" "main" {
    cluster_name = aws_eks_cluster.eks_cluster.name
    node_group_name = "node-group-01"
    node_role_arn = "arn:aws:iam::${var.accountId}:role/LabRole"
    subnet_ids = [
        local.private_subnet_ids[0],
        local.private_subnet_ids[1]
    ]
    instance_types = [
        "t3.medium"
    ]
    # 5 microserviços × 2 réplicas + Ingress NGINX + RabbitMQ + DaemonSets.
    # 3 nodes t3.medium cobrem com folga; teto em 5 para HPAs eventuais.
    scaling_config {
        desired_size = 3
        max_size     = 5
        min_size     = 2
    }
    update_config {
        max_unavailable = 1
    }
    depends_on = [
        aws_eks_cluster.eks_cluster
    ]
}

# Controle de acesso no EKS - permite que usuários interajam com o cluster
resource "aws_eks_access_entry" "access-entry" {
    cluster_name  = aws_eks_cluster.eks_cluster.name
    principal_arn = "arn:aws:iam::${var.accountId}:role/${var.roleName}"
    kubernetes_groups = [
    ]
    type = "STANDARD"
}

resource "aws_eks_access_policy_association" "eks-policy" {
    cluster_name  = aws_eks_cluster.eks_cluster.name
    policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    principal_arn = "arn:aws:iam::${var.accountId}:role/${var.roleName}"
    access_scope {
        type = "cluster"
    }
}

########################################
# EKS ACCESS - AWS ACADEMY (voclabs)
########################################

# Permite que a role "voclabs" (usada pelo AWS Academy) tenha acesso ao cluster EKS
# Sem isso, comandos como: `kubectl get nodes` falham com erro de autenticação
resource "aws_eks_access_entry" "access-voclabs" {
    cluster_name  = aws_eks_cluster.eks_cluster.name

    # Role real usada na autenticação via AWS CLI
    # aws sts get-caller-identity
    # -> assumed-role/voclabs/...
    principal_arn = "arn:aws:iam::${var.accountId}:role/voclabs"

    # STANDARD = acesso via RBAC do Kubernetes
    type = "STANDARD"
}

# Associa uma policy administrativa ao cluster
# para a role voclabs, permite kubectl apply, kubectl get nodes, criação de recursos no cluster
resource "aws_eks_access_policy_association" "eks-policy-voclabs" {
    cluster_name  = aws_eks_cluster.eks_cluster.name

    # Policy oficial da AWS para admin do cluster
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

    principal_arn = "arn:aws:iam::${var.accountId}:role/voclabs"

    access_scope {
        # Escopo em nível de cluster
        type = "cluster"
    }
}


# Ponto de entrada no cluster agora é o Ingress NGINX (ver ingress.tf),
# provisionado via Helm. O Service genérico `garage-app` foi removido junto
# com o monólito.
