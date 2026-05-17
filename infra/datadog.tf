########################################
# DATADOG AGENT — DaemonSet via Helm
########################################

# Implanta o Datadog Agent como DaemonSet em todos os nós EKS.
# O Agent escuta na porta 8126 (APM/traces) e 8125/udp (DogStatsD) no host IP,
# que os pods acessam via DD_AGENT_HOST=status.hostIP.
resource "null_resource" "datadog_agent" {
    triggers = {
        cluster_name = aws_eks_cluster.eks_cluster.name
        dd_site      = "us5.datadoghq.com"
    }

    depends_on = [
        aws_eks_node_group.main,
        aws_eks_access_policy_association.eks-policy
    ]

    provisioner "local-exec" {
        command = <<-EOT
            aws eks update-kubeconfig --region ${local.awsRegion} --name ${aws_eks_cluster.eks_cluster.name}

            kubectl create namespace datadog --dry-run=client -o yaml | kubectl apply -f -

            kubectl create secret generic datadog-agent-secret \
                --namespace datadog \
                --from-literal=api-key="${var.dd_api_key}" \
                --dry-run=client -o yaml | kubectl apply -f -

            helm repo add datadog https://helm.datadoghq.com 2>/dev/null || true
            helm repo update datadog

            helm upgrade --install datadog-agent datadog/datadog \
                --namespace datadog \
                --set datadog.apiKeyExistingSecret=datadog-agent-secret \
                --set datadog.apiKeyExistingSecretKey=api-key \
                --set datadog.site="us5.datadoghq.com" \
                --set datadog.apm.portEnabled=true \
                --set datadog.logs.enabled=true \
                --set datadog.logs.containerCollectAll=true \
                --set datadog.dogstatsd.useHostPort=true \
                --set datadog.dogstatsd.nonLocalTraffic=true \
                --set datadog.criSocketPath=/var/run/containerd/containerd.sock \
                --set agents.image.tag=7 \
                --wait --timeout=10m
        EOT
    }
}
