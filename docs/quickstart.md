# Quick Start - 5 Minutos

Deploy da aplicação exemplo e teste básico.

**Pré-requisito:** Você já completou [COMO-COMECAR.md](COMO-COMECAR.md)

> **Nota:** Este guia usa caminhos variáveis. Substitua conforme sua realidade.

---

## 1️⃣ Conectar à VM

### Via WSL (Linux)

```bash
cd /mnt/c/Users/[seu-usuario]/[seu-caminho-pasta-projeto]
# ou se preferir usar o caminho direto
cd [seu-caminho-correspondente-linux]

vagrant ssh
```

### Via Mac/Linux

```bash
cd ~/[seu-caminho-pasta-projeto]
vagrant ssh
```

### Via Windows PowerShell/CMD

```bash
cd C:\Users\[seu-usuario]\[seu-caminho-pasta-projeto]
vagrant ssh
```

---

## 2️⃣ Build da Aplicação

Dentro da VM:

```bash
cd [caminho-dentro-da-vm]/apps/hello-api

# Build da imagem Docker
docker build -t hello-api:v1 .

# Verificar que foi criada
docker images | grep hello-api
```

> **Nota:** Dentro da VM, o caminho geralmente é `/home/vagrant/` ou pode acessar via `/vagrant/`

---

## 3️⃣ Deploy no Kubernetes

```bash
# Deploy
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/serviceaccount.yaml

# Verificar
kubectl get pods
kubectl get svc

# Aguardar até que apareça: 1/1 Running
kubectl wait --for=condition=Ready pods -l app=hello-api --timeout=60s
```

---

## 4️⃣ Testar a Aplicação

```bash
# Health check
curl http://localhost:8080/health

# Info endpoint
curl http://localhost:8080/api/info

# Hello endpoint
curl http://localhost:8080/api/hello

# Todos devem retornar JSON com status 200 ✅
```

---

## 5️⃣ Ver Logs

```bash
# Logs em tempo real
kubectl logs -f deployment/hello-api

# Ver última linha
kubectl logs deployment/hello-api --tail=5
```

---

## 6️⃣ Verificar no Argo CD

Se já criou a application em [COMO-COMECAR.md](COMO-COMECAR.md):

```bash
# Status via CLI
argocd app get hello-api

# Deve mostrar: Synced ✅

# Ou abrir no navegador
# http://localhost:8080 → hello-api → ver sincronização
```

---

## Se Tudo Funcionou ✅

Parabéns! Você tem:
- ✅ Kubernetes rodando
- ✅ Argo CD sincronizado
- ✅ Aplicação deployada
- ✅ Endpoints respondendo

---

## Próximos Passos

### Teste 1: Modificar Código (GitOps)

```bash
# Modificar main.py
vim [caminho-relativo]/apps/hello-api/src/main.py

# Ou abra no seu editor favorito
code [caminho-relativo]/apps/hello-api/src/main.py

# Adicionar um novo endpoint ou mudar mensagem

# Rebuild
docker build -t hello-api:v2 .

# Update deployment
kubectl set image deployment/hello-api hello-api=hello-api:v2

# Verificar
kubectl rollout status deployment/hello-api
curl http://localhost:8080/api/hello
```

### Teste 2: Scanning com Trivy

```bash
# Scan de vulnerabilidades
trivy image hello-api:v1

# Saída JSON
trivy image --format json hello-api:v1 > report.json
```

### Teste 3: Entender o Fluxo

Próximo: Leia [DEVSECOPS.md](DEVSECOPS.md) para entender como tudo se conecta.

---

## Problemas Comuns

### Pod em CrashLoopBackOff

```bash
# Ver logs de erro
kubectl logs deployment/hello-api

# Descrever o pod
kubectl describe pod <pod-name>

# Tentar novamente
kubectl rollout restart deployment/hello-api
```

### Curl retorna "Connection refused"

```bash
# Verificar que serviço está rodando
kubectl get svc hello-api

# Deve ter: 80:30080

# Se não tiver, aplicar novamente
kubectl apply -f k8s/service.yaml
```

### Argo CD não sincroniza

```bash
# Forçar sincronização
argocd app sync hello-api --force

# Ou ver status detalhado
argocd app get hello-api
```

---

## Leitura Recomendada

Agora que tudo está rodando, leia:

1. **[DEVSECOPS.md](DEVSECOPS.md)** - Entender o fluxo completo e conceitos
2. **[SETUP-GITHUB.md](SETUP-GITHUB.md)** - Configurar GitHub Actions e CI/CD automático
3. **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Se tiver problemas

---

## Referência de Caminhos

| Local | Caminho |
|-------|---------|
| **Seu computador (Windows)** | `C:\Users\[seu-usuario]\[seu-caminho]` |
| **Seu computador (Mac/Linux)** | `~/[seu-caminho]` |
| **Dentro da VM** | `/home/vagrant/` ou `/vagrant/` |
| **Via WSL** | `/mnt/c/Users/[seu-usuario]/[seu-caminho]` |

---

**5 minutos concluídos! Próximo: [DEVSECOPS.md](DEVSECOPS.md)** 🚀
