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
    awsRegion   = "us-east-1"
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
        bucket = "garage-terraform-state-211125475874"
        key    = "database/terraform.tfstate"
        region = "us-east-1"
    }
}

locals {
    vpc_id             = data.terraform_remote_state.database.outputs.vpc_id
    public_subnet_ids  = data.terraform_remote_state.database.outputs.public_subnet_ids
    private_subnet_ids = data.terraform_remote_state.database.outputs.private_subnet_ids
}
