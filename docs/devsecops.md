# 🔐 DevSecOps & GitOps - Guia Completo

Entenda os conceitos e o fluxo de trabalho do laboratório.

---

## 📚 Conceitos Fundamentais

### O que é DevSecOps?

**DevSecOps** = **Dev** (Desenvolvimento) + **Sec** (Segurança) + **Ops** (Operações)

Integra segurança em **cada estágio** do ciclo de vida de desenvolvimento:

```
Code → Build → Test → Security → Deploy → Monitor
                  ↑ (segurança aqui!)
```

### O que é GitOps?

**GitOps** usa Git como "fonte da verdade" para infraestrutura e aplicações.

```
Developer push → Git repo → Argo CD (sincroniza) → Kubernetes (aplica)
```

---

## 🔄 Fluxo Completo (passo a passo)

### Fase 1: Desenvolvimento

1. **Developer escreve código**
   ```bash
   # Modificar código
   vim apps/hello-api/src/main.py
   
   # Commitar
   git add .
   git commit -m "Feature: novo endpoint"
   git push origin main
   ```

2. **GitHub Actions é disparado**
   - Webhook do GitHub notifica Actions
   - CI/CD pipeline inicia

### Fase 2: CI/CD (GitHub Actions)

```
┌─────────────────────────────────────────┐
│     GitHub Actions (CI/CD Pipeline)    │
├─────────────────────────────────────────┤
│ 1. Checkout código                      │
│ 2. Build Docker image                   │
│ 3. Scan com Trivy (SAST)                │
│ 4. Scan de vulnerabilidades             │
│    - Críticas: ❌ FAIL                   │
│    - Altas/Médias: ⚠️ WARN              │
│ 5. Push para Container Registry         │
│ 6. Update deployment.yaml               │
│ 7. Push do manifests ao Git             │
└─────────────────────────────────────────┘
```

#### Passo 2.1: Build da Imagem Docker

```bash
# Dockerfile com boas práticas de segurança
FROM python:3.12-slim as builder
  # Multi-stage build (reduz tamanho)
  # Usuário não-root
  # Health checks
  # Sem permissões privilegiadas
```

#### Passo 2.2: Scanning com Trivy

```bash
# Scan a imagem
trivy image hello-api:sha256

# Relatorio de vulnerabilidades
CRITICAL   : 0
HIGH       : 2
MEDIUM     : 5
LOW        : 12
```

**O que acontece:**
- ✅ Se CRÍTICAS = 0 → Continua
- ❌ Se CRÍTICAS > 0 → Pipeline falha (não faz deploy)

#### Passo 2.3: Push para Registry

```bash
docker push ghcr.io/usuario/hello-api:sha256
```

#### Passo 2.4: Update dos Manifests

O Actions atualiza o deployment.yaml:

```yaml
# Antes
spec:
  containers:
  - name: hello-api
    image: hello-api:latest

# Depois (automático)
spec:
  containers:
  - name: hello-api
    image: ghcr.io/usuario/hello-api:abc123def456
```

### Fase 3: GitOps (Argo CD)

```
┌──────────────────────────────────────────┐
│    Argo CD (GitOps Reconciliation)      │
├──────────────────────────────────────────┤
│ 1. Detecta mudanças no Git               │
│ 2. Compara Git ↔ Kubernetes              │
│ 3. Se diferente:                         │
│    - Aplica manifests atualizados        │
│    - Cria novo Deployment                │
│    - Rolling update dos pods             │
│ 4. Sincroniza estado                     │
│ 5. Relata status                         │
└──────────────────────────────────────────┘
```

**Automático:**
```bash
# Argo CD está sempre observando
watch git diff

# Se houver alterações
kubectl apply -f k8s/deployment.yaml
```

### Fase 4: Deploy no Kubernetes

```
┌──────────────────────────────────────────┐
│   Kubernetes (Rolling Update)           │
├──────────────────────────────────────────┤
│ 1. Novo replica set criado               │
│ 2. Novos pods com nova imagem            │
│ 3. Health checks passam?                 │
│    - Não: Rollback automático            │
│    - Sim: Continua                       │
│ 4. Traffic movido gradualmente           │
│ 5. Pods antigos terminados               │
│ 6. Deploy completo!                      │
└──────────────────────────────────────────┘
```

### Fase 5: Monitoramento & Logs

```bash
# Verificar status em tempo real
kubectl rollout status deployment/hello-api

# Logs da nova versão
kubectl logs -f deployment/hello-api

# Health check
curl http://localhost:8080/health
```

---

## 🔐 Camadas de Segurança

### Camada 1: Build Security

**O que é:**
- Imagens Docker limpas (multi-stage)
- Sem secrets no código
- Sem dependências vulneráveis
- User não-root

**Verifica:**
```bash
trivy image hello-api:v1
```

### Camada 2: Image Security

**O que é:**
- Scan de vulnerabilidades (CVEs)
- Análise de camadas
- Detecção de secrets

**Verifica:**
```bash
# SAST (Static Application Security Testing)
trivy image --severity CRITICAL,HIGH hello-api:v1

# Falha se crítico
trivy image --exit-code 1 --severity CRITICAL hello-api:v1
```

### Camada 3: Runtime Security

**O que é:**
- Security Context (container)
- Network Policies
- RBAC (permissões)
- Pod Security Policy

**Exemplo:**
```yaml
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  capabilities:
    drop:
    - ALL
```

### Camada 4: Deployment Security

**O que é:**
- GitOps (auditável)
- Aprovações antes do deploy
- Rollback automático
- Health checks

**Exemplo:**
```yaml
livenessProbe:
  httpGet:
    path: /health
  periodSeconds: 30
  failureThreshold: 3
```

---

## 📊 Exemplos Práticos

### Cenário 1: Vulnerabilidade Crítica Detectada

```
Developer código → GitHub
                  ↓
GitHub Actions inicia build
                  ↓
Build: ✅ OK
                  ↓
Trivy Scan: ❌ FALHA
  - Vulnerabilidade CRÍTICA em numpy
                  ↓
Pipeline FALHA → Sem deploy
                  ↓
Developer é notificado ✉️
                  ↓
Developer corrige dependência
                  ↓
git push (retry)
                  ↓
Retry build → Sucesso!
                  ↓
Deploy automático ✅
```

### Cenário 2: Deploy com Rollback Automático

```
Novo deployment iniciado
      ↓
Health check falha ❌
      ↓
Kubernetes detecta: Pod não pronto
      ↓
Aguarda (5 tentativas)
      ↓
Continua falhando
      ↓
Rollback automático! 🔄
      ↓
Versão anterior voltada
      ↓
Alert enviado ao time
```

### Cenário 3: GitOps - Sincronização Automática

```
Developer altera manifests no Git
      ↓
git push
      ↓
Argo CD detecta mudança
      ↓
Compara: Git vs Cluster
      ↓
Diferenças encontradas
      ↓
Argo aplica as mudanças
      ↓
Kubernetes sincroniza
      ↓
App atualizada!
```

---

## 🛠️ Ferramentas & Responsabilidades

| Ferramenta | Responsabilidade | Comando |
|-----------|-----------------|---------|
| **GitHub Actions** | Build + Scan | `git push` (automático) |
| **Trivy** | Scanning segurança | `trivy image hello-api:v1` |
| **Docker** | Build de imagem | `docker build -t hello-api:v1 .` |
| **kubectl** | Deploy manual | `kubectl apply -f k8s/` |
| **Argo CD** | Deploy automático | `argocd app sync hello-api` |
| **Kubernetes** | Orquestração | `kubectl get pods` |

---

## 📈 Métricas & Observabilidade

### O que Monitorar?

1. **Vulnerabilidades**
   ```bash
   trivy image --severity HIGH,CRITICAL hello-api:v1 | grep -c HIGH
   ```

2. **Pod Health**
   ```bash
   kubectl get pods -o wide
   kubectl logs -f deployment/hello-api
   ```

3. **Argo CD Sync**
   ```bash
   argocd app get hello-api
   ```

4. **Deployment Status**
   ```bash
   kubectl rollout status deployment/hello-api
   ```

---

## 🚀 Best Practices

### Development

✅ **DO:**
- Escrever código seguro
- Usar dependências atualizadas
- Fazer testes locais
- Commitar com mensagens claras

❌ **DON'T:**
- Commitar secrets
- Usar `latest` para versões
- Ignorar warnings de scan

### CI/CD

✅ **DO:**
- Falhar em vulnerabilidades críticas
- Fazer scan antes do deploy
- Usar multi-stage Docker builds
- Manter registros de auditoria

❌ **DON'T:**
- Fazer bypass de segurança
- Deployar diretamente em prod
- Ignorar relatórios de segurança

### Kubernetes

✅ **DO:**
- Usar Security Context
- Limitar recursos (limits/requests)
- Health checks (liveness/readiness)
- Network Policies
- RBAC apropriado

❌ **DON'T:**
- Correr como root
- Sem limites de recursos
- Sem health checks
- Permissões excessivas

---

## 🔍 Debug & Troubleshooting

### Problema: Pipeline falhando no Trivy

```bash
# Verificar vulnerabilidades
trivy image hello-api:v1

# Atualizar dependências
pip install --upgrade -r requirements.txt

# Rebuild
docker build -t hello-api:v2 .

# Rescan
trivy image hello-api:v2
```

### Problema: Argo CD não sincroniza

```bash
# Verificar status
argocd app get hello-api

# Ver logs
kubectl logs -f deployment/argocd-server -n argocd

# Forçar sync
argocd app sync hello-api --force
```

### Problema: Pod não fica pronto

```bash
# Ver eventos
kubectl describe pod <pod-name>

# Ver logs
kubectl logs <pod-name>

# Verificar resources
kubectl top pod <pod-name>
```

---

## 📚 Recursos Adicionais

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [OWASP DevSecOps](https://owasp.org/www-project-devsecops/)

---

**Próximo:** Configure GitHub Actions para seu repositório!
