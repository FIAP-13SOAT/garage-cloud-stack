terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "6.17.0"
        }
        random = {
            source  = "hashicorp/random"
            version = "~> 3.6"
        }
        tls = {
            source  = "hashicorp/tls"
            version = "~> 4.0"
        }
        kubernetes = {
            source  = "hashicorp/kubernetes"
            version = "~> 2.30"
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

    services = toset([
        "garage-auth-service",
        "garage-os-service",
        "garage-billing-service",
        "garage-execution-service",
        "garage-stock-service",
    ])

    pg_services = {
        "garage-auth-service"    = "auth"
        "garage-os-service"      = "os"
        "garage-billing-service" = "billing"
        "garage-stock-service"   = "stock"
    }
}

provider "aws" {
    region = local.awsRegion
}

provider "kubernetes" {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks_cluster.name]
    }
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
