#!/usr/bin/env bash
set -e

echo "===> [2/3] Criando cluster Kubernetes com Kind..."

# Garantir que Docker está rodando
sudo service docker start 2>/dev/null || true

# Adicionar vagrant ao grupo docker
sudo usermod -aG docker vagrant

# Ativar o grupo docker para o usuário atual
sg docker -c "
cat <<EOF > /tmp/kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 8080
    protocol: TCP
EOF

# Criar cluster Kind com permissões do grupo docker
kind create cluster --name lab1-cluster --config /tmp/kind-config.yaml

# Configura o kubeconfig para o usuário vagrant
mkdir -p \$HOME/.kube
sudo cp /root/.kube/config \$HOME/.kube/config 2>/dev/null || true
sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config 2>/dev/null || true

kubectl cluster-info --context kind-lab1-cluster
echo '===> Cluster Kind lab1-cluster ativo!'
"
