########################################
# DATABASE
########################################

# RDS PostgreSQL - banco de dados da aplicação
resource "aws_db_instance" "postgres" {
    identifier = "${local.projectName}-postgres"

    engine         = "postgres"
    engine_version = "16.11"
    instance_class = "db.t3.micro"

    allocated_storage = 20
    storage_type      = "gp2"

    db_name  = "garage"
    username = "postgres"
    manage_master_user_password = true

    vpc_security_group_ids = [aws_security_group.rds.id]
    db_subnet_group_name   = aws_db_subnet_group.main.name

    skip_final_snapshot = true

    tags = {
        Name = "${local.projectName}-postgres"
    }
}
