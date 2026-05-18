########################################
# DATABASE_URL por serviço (PostgreSQL)
#
# Cada serviço PG tem sua própria instância RDS provisionada em
# garage-database-infra (auth, os, billing, stock). A senha master é
# gerenciada pela AWS e armazenada em Secrets Manager (o ARN vem via
# remote state). Aqui montamos a connection string Prisma e publicamos
# em SSM, espelhando o padrão do RabbitMQ.
########################################

locals {
    db_endpoints   = data.terraform_remote_state.database.outputs.rds_endpoints
    db_secret_arns = data.terraform_remote_state.database.outputs.db_secret_arns
}

# Resolve o JSON da senha master criada pelo RDS para cada serviço.
data "aws_secretsmanager_secret_version" "db" {
    for_each  = local.pg_services
    secret_id = local.db_secret_arns[each.value]
}

locals {
    db_credentials = {
        for service_key, db_name in local.pg_services :
        service_key => jsondecode(data.aws_secretsmanager_secret_version.db[service_key].secret_string)
    }

    database_urls = {
        for service_key, db_name in local.pg_services :
        service_key => format(
            "postgresql://%s:%s@%s/%s?sslmode=require",
            local.db_credentials[service_key].username,
            local.db_credentials[service_key].password,
            local.db_endpoints[db_name],
            db_name,
        )
    }
}

resource "aws_ssm_parameter" "service_db_url" {
    for_each = local.pg_services

    name      = "/${local.projectName}/prod/${each.key}/database_url"
    type      = "SecureString"
    overwrite = true
    value     = local.database_urls[each.key]
}
