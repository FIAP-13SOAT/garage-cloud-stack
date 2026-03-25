accountId = "211125475874"
roleName = "LabRole"

# =============================================================================
# EKS Load Balancer Listener ARN
# =============================================================================
# Este ARN é necessário para ativar os recursos condicionais no api_gateway.tf:
#   - aws_apigatewayv2_vpc_link.eks_link (VPC Link para o EKS)
#   - aws_apigatewayv2_integration.eks_integration (integração HTTP_PROXY)
#   - aws_apigatewayv2_route.protected (rota protegida com Lambda Authorizer)
#
# Quando esta variável estiver vazia (""), esses recursos NÃO serão criados.
# Quando preenchida com um ARN válido, o API Gateway roteará requisições
# autenticadas para a aplicação via VPC Link e Load Balancer interno do EKS.
#
# Para obter o ARN real do listener, execute os seguintes comandos:
#
#   1. Listar os Load Balancers para encontrar o LB interno do EKS:
#      aws elbv2 describe-load-balancers --query "LoadBalancers[?Scheme=='internal'].[LoadBalancerArn,DNSName]" --output table
#
#   2. Obter o ARN do listener do Load Balancer identificado:
#      aws elbv2 describe-listeners --load-balancer-arn <LOAD_BALANCER_ARN> --query "Listeners[*].ListenerArn" --output text
#
#   3. Substituir o valor abaixo pelo ARN retornado no passo 2.
#
# Formato esperado do ARN:
#   arn:aws:elasticloadbalancing:<REGION>:<ACCOUNT_ID>:listener/net/<LB_NAME>/<LB_ID>/<LISTENER_ID>
#
# Exemplo:
#   eks_lb_listener_arn = "arn:aws:elasticloadbalancing:us-east-1:211125475874:listener/net/k8s-internal-lb/abc123def456/789ghi012jkl"
# =============================================================================
eks_lb_listener_arn = "arn:aws:elasticloadbalancing:us-east-1:211125475874:listener/net/a4ee653aa3e0341219456eabc66f88c0/23cec29ca3a0c20c/7e7e554426f7c2c7"
