########################################
# Kubernetes Secrets espelhados a partir do SSM Parameter Store
#
# Os Deployments de cada serviço referenciam <service>-secrets via
# secretKeyRef. Em vez de obrigar cada app a falar com o SSM (e exigir
# IRSA, que é problemático em AWS Academy), espelhamos os valores em
# K8s Secrets aqui — Terraform é a fonte de sincronia.
########################################

locals {
    rabbitmq_url = format(
        "amqps://admin:%s@%s",
        random_password.rabbitmq.result,
        aws_mq_broker.rabbitmq.instances[0].endpoints[0],
    )
}

resource "kubernetes_secret" "datadog" {
    metadata {
        name      = "datadog-secrets"
        namespace = "default"
    }

    data = {
        DD_API_KEY = var.dd_api_key
    }

    depends_on = [aws_eks_node_group.main]
}

resource "kubernetes_secret" "pg_service" {
    for_each = local.pg_services

    metadata {
        name      = "${each.key}-secrets"
        namespace = "default"
    }

    data = merge(
        {
            DATABASE_URL = local.database_urls[each.key]
            RABBITMQ_URL = local.rabbitmq_url
        },
        each.key == "garage-auth-service" ? {
            JWT_PRIVATE_KEY = tls_private_key.jwt.private_key_pem
            JWT_PUBLIC_KEY  = tls_private_key.jwt.public_key_pem
        } : {},
    )

    depends_on = [aws_eks_node_group.main]
}

########################################
# MongoDB connection string vem do SSM provisionado pelo garage-database-infra
# (a EC2 do Mongo e o parâmetro são criados lá; aqui só consumimos).
########################################

data "aws_ssm_parameter" "execution_mongo_url" {
    name            = "/${local.projectName}/prod/garage-execution-service/mongo_url"
    with_decryption = true
}

resource "kubernetes_secret" "execution" {
    metadata {
        name      = "garage-execution-service-secrets"
        namespace = "default"
    }

    data = {
        MONGO_URL    = data.aws_ssm_parameter.execution_mongo_url.value
        RABBITMQ_URL = local.rabbitmq_url
    }

    depends_on = [aws_eks_node_group.main]
}
