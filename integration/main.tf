terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "6.17.0"
        }
    }

    backend "s3" {
        bucket = "garage-integration-terraform-state-381492225614"
        key    = "terraform.tfstate"
        region = "us-east-1"
    }
}

locals {
    projectName = "garage"
    dns = "fiapgarage2026.com"
    awsRegion = "us-east-1"
}

provider "aws" {
    region = local.awsRegion
}

