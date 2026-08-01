#!/usr/bin/env bash
set -e

echo "===> [3/3] Instalando Argo CD com Helm..."

# Ativar grupo docker para comandos kubectl/helm
sg docker -c "

# Aguardar cluster estar completamente pronto
echo 'Aguardando cluster estar pronto...'
kubectl wait --for=condition=Ready nodes --all --timeout=300s 2>/dev/null || true
sleep 10

# Adicionar repositório Helm do Argo CD
echo 'Adicionando repositório Helm do Argo CD...'
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Criar namespace argocd
echo 'Criando namespace argocd...'
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Instalar Argo CD via Helm
echo 'Instalando Argo CD via Helm...'
helm install argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=NodePort \
  --set server.service.nodePort=30080 \
  --wait \
  --timeout 5m

# Aguardar Argo CD ficar pronto
echo 'Aguardando Argo CD estar pronto...'
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s 2>/dev/null || true

# Obter credenciais do Argo CD
ARGOCD_PASSWORD=\$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || echo 'admin')

echo ''
echo '=========================================='
echo '===> Argo CD instalado com sucesso! ====='
echo '=========================================='
echo ''
echo 'Acesse em: http://localhost:8080'
echo 'Usuário: admin'
echo \"Senha: \$ARGOCD_PASSWORD\"
echo ''
"
