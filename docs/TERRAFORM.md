# Infraestrutura AWS com Terraform

Esse projeto usa Terraform para provisionar infraestrutura completa na AWS: VPC, RDS PostgreSQL e cluster EKS.

## Pré-requisitos

1. **Instalar Terraform**: https://developer.hashicorp.com/terraform/install
2. **Configurar AWS CLI**: `aws configure` com suas credenciais
3. **Verificar acesso**: `aws sts get-caller-identity`

## Configuração

### 1. Criar arquivo terraform.tfvars

```hcl
accountId = "964022050595"  # Seu AWS Account ID
roleName  = "LabRole"        # Nome da sua IAM Role

# Usar role existente (obrigatório para AWS Academy)
eks_cluster_role_arn = "arn:aws:iam::964022050595:role/LabRole"
eks_node_group_role_arn = "arn:aws:iam::964022050595:role/LabRole"
```

### 2. Descobrir seus valores

```bash
# Account ID
aws sts get-caller-identity --query Account --output text

# Role ARN (extrair o nome da role)
aws sts get-caller-identity --query Arn --output text
```

## Deploy da Infraestrutura

```bash
cd infra

# 1. Inicializar Terraform
terraform init

# 2. Validar configuração
terraform validate

# 3. Ver plano de execução
terraform plan

# 4. Aplicar mudanças (aguardar ~15 minutos)
terraform apply

# 5. Anotar os outputs
terraform output
```

## Recursos Criados

### Rede
- **VPC** (10.0.0.0/16)
- **Subnet Pública** (10.0.1.0/24) - us-east-1a
- **Subnet Privada** (10.0.2.0/24) - us-east-1a
- **Subnet Privada B** (10.0.3.0/24) - us-east-1b
- **Security Groups** para EKS e RDS

### Banco de Dados
- **RDS PostgreSQL 14.9**
- Instância: db.t3.micro
- Storage: 20GB gp2
- Multi-AZ: Não
- Backup: Desabilitado (skip_final_snapshot)

### Kubernetes
- **Cluster EKS** (garage-cluster)
- **Node Group** com 2-3 instâncias t3.medium
- Auto-scaling: 1 min, 3 max, 2 desired
- Usa LabRole existente (sem criar IAM roles)

## Conectar ao Cluster

```bash
# Configurar kubectl
aws eks update-kubeconfig --region us-east-1 --name garage-cluster

# Verificar conexão
kubectl get nodes
```

## Outputs Importantes

```bash
# Endpoint do cluster EKS
terraform output kubeconfig

# Endpoint do RDS (usar no ConfigMap do Kubernetes)
terraform output rds_endpoint

# Porta do RDS
terraform output rds_port
```

## Troubleshooting

### Erro: AccessDenied ao criar IAM Role
**Solução**: Use a LabRole existente no terraform.tfvars (já configurado)

### Erro: Versão do PostgreSQL não disponível
**Solução**: Versão 14.9 é estável e amplamente suportada

### Erro: Timeout ao criar EKS
**Solução**: Aguarde até 20 minutos, é normal para criação de cluster

## Destruir Infraestrutura

```bash
# ATENÇÃO: Remove TODOS os recursos
terraform destroy
```
