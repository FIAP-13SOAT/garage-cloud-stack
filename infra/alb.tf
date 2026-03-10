# 1. Security Group para o ALB (Permitir tráfego na porta 80/443)
resource "aws_security_group" "alb_sg" {
    name        = "${local.projectName}-alb-sg"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# 2. O Application Load Balancer
resource "aws_lb" "main" {
    name               = "${local.projectName}-alb"
    internal           = true # IMPORTANTE: Como você usa VPC Link, ele deve ser interno
    load_balancer_type = "application"
    security_groups    = [aws_security_group.alb_sg.id]
    subnets            = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_b.id]
}

# 3. Target Group (Onde os Pods do K8s vão se registrar)
resource "aws_lb_target_group" "k8s_app" {
    name        = "${local.projectName}-tg"
    port        = 80
    protocol    = "HTTP"
    target_type = "ip" # O EKS registra os IPs dos Pods diretamente
    vpc_id      = aws_vpc.main.id

    health_check {
        path = "/health" # Certifique-se que seu app tem esse endpoint
    }
}

# 4. Listener (O ARN que o API Gateway tanto queria!)
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.main.arn
    port              = "80"
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.k8s_app.arn
    }
}

# 5. Salve o ARN do Target Group no SSM para o Kubernetes usar
resource "aws_ssm_parameter" "target_group_arn" {
    name  = "/garage/prod/garage/target_group_arn"
    type  = "String"
    value = aws_lb_target_group.k8s_app.arn
}
