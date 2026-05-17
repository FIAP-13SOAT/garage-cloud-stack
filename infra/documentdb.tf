########################################
# AWS DocumentDB (MongoDB-compatible) — garage-execution-service
########################################

resource "random_password" "docdb" {
    length  = 24
    special = false
}

resource "aws_security_group" "docdb" {
    name_prefix = "${local.projectName}-docdb-sg"
    vpc_id      = local.vpc_id

    ingress {
        description = "MongoDB wire protocol from VPC (EKS pods)"
        from_port   = 27017
        to_port     = 27017
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
        Name = "${local.projectName}-docdb-security-group"
    }
}

resource "aws_docdb_subnet_group" "main" {
    name       = "${local.projectName}-docdb-subnet-group"
    subnet_ids = [local.private_subnet_ids[0], local.private_subnet_ids[1]]
}

resource "aws_docdb_cluster" "execution" {
    cluster_identifier     = "${local.projectName}-execution"
    engine                 = "docdb"
    master_username        = "garage"
    master_password        = random_password.docdb.result
    db_subnet_group_name   = aws_docdb_subnet_group.main.name
    vpc_security_group_ids = [aws_security_group.docdb.id]
    skip_final_snapshot    = true
    apply_immediately      = true
    storage_encrypted      = true
}

resource "aws_docdb_cluster_instance" "execution" {
    count              = 1
    identifier         = "${local.projectName}-execution-${count.index}"
    cluster_identifier = aws_docdb_cluster.execution.id
    instance_class     = "db.t3.medium"
}

########################################
# SSM — Mongo connection string for garage-execution-service
########################################

resource "aws_ssm_parameter" "execution_mongo_url" {
    name      = "/${local.projectName}/prod/garage-execution-service/mongo_url"
    type      = "SecureString"
    overwrite = true
    value     = "mongodb://garage:${random_password.docdb.result}@${aws_docdb_cluster.execution.endpoint}:27017/execution?tls=true&retryWrites=false&replicaSet=rs0&readPreference=secondaryPreferred"
}
