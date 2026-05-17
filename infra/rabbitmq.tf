########################################
# AWS MQ — RabbitMQ (broker Saga)
########################################

resource "random_password" "rabbitmq" {
    length  = 24
    special = false
}

resource "aws_security_group" "rabbitmq" {
    name_prefix = "${local.projectName}-mq-sg"
    vpc_id      = local.vpc_id

    ingress {
        description = "AMQPS from VPC"
        from_port   = 5671
        to_port     = 5671
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
        Name = "${local.projectName}-mq-security-group"
    }
}

resource "aws_mq_broker" "rabbitmq" {
    broker_name        = "${local.projectName}-rabbitmq"
    engine_type        = "RabbitMQ"
    engine_version     = "3.13"
    host_instance_type = "mq.t3.micro"
    deployment_mode    = "SINGLE_INSTANCE"

    subnet_ids          = [local.private_subnet_ids[0]]
    security_groups     = [aws_security_group.rabbitmq.id]
    publicly_accessible = false

    user {
        username = "admin"
        password = random_password.rabbitmq.result
    }
}

########################################
# SSM — RabbitMQ connection params
########################################

resource "aws_ssm_parameter" "rabbitmq_endpoint" {
    name      = "/${local.projectName}/prod/rabbitmq/endpoint"
    type      = "String"
    value     = aws_mq_broker.rabbitmq.instances[0].endpoints[0]
    overwrite = true
}

resource "aws_ssm_parameter" "rabbitmq_username" {
    name      = "/${local.projectName}/prod/rabbitmq/username"
    type      = "String"
    value     = "admin"
    overwrite = true
}

resource "aws_ssm_parameter" "rabbitmq_password" {
    name      = "/${local.projectName}/prod/rabbitmq/password"
    type      = "SecureString"
    value     = random_password.rabbitmq.result
    overwrite = true
}
