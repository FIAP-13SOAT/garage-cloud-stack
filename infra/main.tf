terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "6.17.0"
        }
        kubernetes = {
            source  = "hashicorp/kubernetes"
            version = "~> 2.30"
        }
        helm = {
            source  = "hashicorp/helm"
            version = "~> 2.13"
        }
        random = {
            source  = "hashicorp/random"
            version = "~> 3.6"
        }
    }

    backend "s3" {
        bucket = "garage-terraform-state-500431122450"
        key    = "terraform.tfstate"
        region = "us-east-1"
    }
}

locals {
    projectName = "garage"
    awsRegion   = "us-east-1"

    services = [
        "auth",
        "billing",
        "execution",
        "os",
        "stock",
    ]

    sharedNamespace = "garage-shared"
}

provider "aws" {
    region = local.awsRegion
}

########################################
# REMOTE STATE - Network from garage-database-infra
########################################

data "terraform_remote_state" "database" {
    backend = "s3"
    config = {
        bucket = "garage-terraform-state-500431122450"
        key    = "database/terraform.tfstate"
        region = "us-east-1"
    }
}

locals {
    vpc_id             = data.terraform_remote_state.database.outputs.vpc_id
    public_subnet_ids  = data.terraform_remote_state.database.outputs.public_subnet_ids
    private_subnet_ids = data.terraform_remote_state.database.outputs.private_subnet_ids
}

########################################
# KUBERNETES + HELM PROVIDERS
# Autenticados via aws_eks_cluster_auth para que os recursos kubernetes_*
# e helm_release apliquem direto no garage-cluster criado em eks.tf.
########################################

data "aws_eks_cluster_auth" "eks" {
    name = aws_eks_cluster.eks_cluster.name
}

provider "kubernetes" {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
    kubernetes {
        host                   = aws_eks_cluster.eks_cluster.endpoint
        cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
        token                  = data.aws_eks_cluster_auth.eks.token
    }
}
