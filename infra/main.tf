terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "6.17.0"
        }
    }

    backend "s3" {
        bucket = "garage-terraform-state-381492225614"
        key    = "terraform.tfstate"
        region = "us-east-1"
    }
}

locals {
    projectName = "garage"
    awsRegion   = "us-east-1"
    environment = "prod"
    dns = "fiapgarage2026.com"
}

provider "aws" {
    region = local.awsRegion
}

