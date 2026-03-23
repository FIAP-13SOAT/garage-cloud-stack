terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "6.17.0"
        }
    }

    backend "s3" {
        bucket = "garage-terraform-state-211125475874"
        key    = "terraform.tfstate"
        region = "us-east-1"
    }
}

locals {
    projectName = "garage"
    awsRegion = "us-east-1"
}

provider "aws" {
    region = local.awsRegion
}

