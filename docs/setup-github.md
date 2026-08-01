# GitHub Actions & CI/CD - Setup Completo

Como configurar GitHub Actions para automação completa de build, scan e deploy.

**Pré-requisito:** Você já completou [COMO-COMECAR.md](COMO-COMECAR.md)

> **Nota:** Este guia usa placeholders para valores que variam por usuário.

---

## O que Vamos Fazer

```
git push → GitHub Actions (build + scan) → GHCR → Argo CD sync → Deploy
```

---

## 1️⃣ Estrutura do Repositório GitHub

```
lab1-devsecops-platform/
├── .github/
│   └── workflows/
│       └── ci.yml                     ← GitHub Actions Pipeline
├── apps/hello-api/
│   ├── src/main.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── k8s/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── serviceaccount.yaml
│       └── argocd-app.yaml            ← Aponta para seu repo GitHub
├── docs/
├── scripts/
├── Vagrantfile
└── README.md
```

---

## 2️⃣ Criar .gitignore

```bash
cat > .gitignore << 'EOF'
# Vagrant
.vagrant/
*.log

# Python
__pycache__/
*.py[cod]
*.egg-info/
.venv/
venv/

# Docker
.dockerignore

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Segurança
*.pem
*.key
.env
.env.local
EOF

git add .gitignore
git commit -m "chore: add gitignore"
git push
```

---

## 3️⃣ Adicionar GitHub Actions Workflow

Crie o arquivo `.github/workflows/ci.yml` no seu repositório:

```bash
mkdir -p .github/workflows
```

Copie o conteúdo do `github-actions-ci.yml` para `.github/workflows/ci.yml`

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add github actions pipeline"
git push
```

---

## 4️⃣ O que o GitHub Actions Faz

### Job 1: build-and-scan

```
1. Checkout código
2. Setup Docker Buildx
3. Login GHCR (automático com GITHUB_TOKEN)
4. Build Docker image
5. Run Trivy scan (SARIF format)
6. Upload results para Security tab
7. Falhar se vulnerabilidades CRITICAL
8. Push image para GHCR (ghcr.io/[seu-usuario]/...)
```

### Job 2: update-k8s-manifests

```
1. Checkout código (com token)
2. Update deployment.yaml com nova imagem tag
3. Commit e push (automático)
```

### Job 3: verify

```
1. Mostrar status final
2. Informar que Argo CD vai sincronizar
```

---

## 5️⃣ GitHub Container Registry (GHCR)

Sua imagem será armazenada em:

```
ghcr.io/[seu-usuario]/lab1-devsecops-platform/hello-api:[hash-commit]
```

**Substituir:**
- `[seu-usuario]` → seu nome de usuário GitHub (ex: `joao-silva`)

### Acessar GHCR (opcional)

Dentro da VM:

```bash
# Login
echo $GITHUB_TOKEN | docker login ghcr.io -u [seu-usuario] --password-stdin

# Listar imagens
curl -u [seu-usuario]:$GITHUB_TOKEN \
  https://ghcr.io/v2/[seu-usuario]/lab1-devsecops-platform/hello-api/tags/list

# Pull imagem (se quiser testar)
docker pull ghcr.io/[seu-usuario]/lab1-devsecops-platform/hello-api:latest
```

---

## 6️⃣ Criar Token GitHub (PAT)

Para autenticar Argo CD com GitHub:

1. GitHub → Settings → Developer settings → Personal access tokens
2. Tokens (classic)
3. Generate new token
4. **Scopes necessários:**
   - ✅ `repo` (repositórios privados)
   - ✅ `write:packages` (GHCR)
5. Copiar token (salve em lugar seguro!)

**Guardar como:**
```
Token: [seu-token-github]
```

---

## 7️⃣ Primeiro Deploy Automático

### Passo 1: Fazer um git push

```bash
# Navegar até seu projeto
cd [seu-caminho-pasta-projeto]

# Modificar código
vim apps/hello-api/src/main.py
# ou
code apps/hello-api/src/main.py

# Mudar algo, ex: adicionar novo endpoint

# Commit e push
git add apps/hello-api/src/main.py
git commit -m "feat: add new endpoint"
git push origin main
```

### Passo 2: GitHub Actions Executa

Vá em: **GitHub → Repositório → Actions**

Você verá:

```
✅ Build, Scan & Deploy
   ├─ build-and-scan
   │   ├─ Checkout código
   │   ├─ Build Docker image
   │   ├─ Run Trivy scan
   │   ├─ Upload Trivy results
   │   └─ Push to ghcr.io
   ├─ update-k8s-manifests
   │   ├─ Update deployment.yaml
   │   └─ Commit & push
   └─ verify
       └─ Status final
```

**Tempo:** ~5-10 minutos

### Passo 3: Argo CD Sincroniza Automaticamente

Dentro da VM:

```bash
# Verificar status
argocd app get hello-api

# Deve mostrar: Syncing → Synced ✅

# Ver logs da sincronização
argocd app logs hello-api

# Verificar novo pod rodando
kubectl get pods -o wide
kubectl logs -f deployment/hello-api
```

### Passo 4: Testar Nova Versão

```bash
# Health check (nova imagem está rodando)
curl http://localhost:8080/health

# Se modificou endpoint, testar novo
curl http://localhost:8080/seu-novo-endpoint
```

---

## 8️⃣ Fluxo de Desenvolvimento Contínuo

### Feature Branch Workflow

```bash
# 1. Criar branch
git checkout -b feature/novo-endpoint

# 2. Modificar código
vim apps/hello-api/src/main.py

# 3. Commit local
git add apps/hello-api/src/main.py
git commit -m "feat: add /metrics endpoint"

# 4. Push
git push origin feature/novo-endpoint

# 5. GitHub Actions roda (mas não faz deploy em main)

# 6. Abrir Pull Request
# GitHub → Pull requests → New PR
# → GitHub Actions valida (build + scan)

# 7. Se tudo OK → Merge para main
# GitHub UI: Merge pull request

# 8. Argo CD sincroniza automaticamente
# (detecta mudanças em main)

# 9. Deploy em produção ✅
```

---

## Segurança GitHub

### Branch Protection Rules

1. GitHub → Repositório → Settings → Branches
2. Add branch protection rule
3. **Branch name:** `main`
4. **Require pull request reviews:** ✅ (mínimo 1)
5. **Require status checks to pass:** ✅ (Actions)
6. **Dismiss stale pull request approvals:** ✅
7. **Save changes**

Agora:
- ✅ Só merge via pull request
- ✅ GitHub Actions precisa passar
- ✅ Código é revisionado antes de deploy

### Dependabot (Automático)

GitHub detecta vulnerabilidades em dependências e cria PRs automaticamente:

- GitHub → Settings → Code security & analysis
- Enable "Dependabot alerts" ✅
- Enable "Dependabot security updates" ✅

---

## Monitorando GitHub Actions

### Ver Execução do Workflow

```bash
# Via CLI (se tiver gh instalado)
gh action run list -R [seu-usuario]/lab1-devsecops-platform

# Via Web
https://github.com/[seu-usuario]/lab1-devsecops-platform/actions
```

### Ver Trivy Reports

```bash
# GitHub → Security → Code scanning
# Todos os CVEs detectados aparecem aqui
```

### Ver GHCR

```bash
# GitHub → Packages
# Ver todas as imagens Docker pusheadas
```

---

## Integração com Argo CD (Já Configurado)

Se já fez [COMO-COMECAR.md](COMO-COMECAR.md):

```bash
# Argo CD está observando seu repositório
argocd app get hello-api

# Quando GitHub Actions atualiza deployment.yaml
# Argo CD detecta mudanças em 1-2 minutos
# e sincroniza automaticamente
```

---

## Troubleshooting GitHub Actions

### Pipeline falha no Trivy

```bash
# Ver logs no GitHub → Actions

# Causas comuns:
# 1. Vulnerabilidade CRITICAL detectada
#    → Solução: Atualizar dependências
pip install --upgrade -r requirements.txt

# 2. Imagem base desatualizada
#    → Solução: Usar nova versão Python
FROM python:3.12-slim  # Mais recente
```

### GitHub Actions não inicia

- Verificar se workflow está em `.github/workflows/ci.yml`
- Verificar sintaxe do YAML (copiar exatamente do template)
- Fazer push para main (não em branch)

### Imagem não pusheia para GHCR

```bash
# GHCR usa GITHUB_TOKEN (automático)
# Verificar se Actions tem permissão:
# GitHub → Settings → Actions → General
# → Workflow permissions: Read and write permissions ✅
```

---

## ✅ Checklist Final

- [ ] `.github/workflows/ci.yml` adicionado
- [ ] `.gitignore` criado
- [ ] Primeiro `git push` feito
- [ ] GitHub Actions rodou com sucesso
- [ ] Trivy scan completou
- [ ] Imagem pushada para GHCR
- [ ] deployment.yaml foi atualizado
- [ ] Argo CD sincronizou
- [ ] Nova versão está rodando no Kubernetes
- [ ] Endpoints respondendo

---

## Próximos Passos

1. ✅ Você tem GitHub Actions rodando
2. ✅ Você tem GitOps com Argo CD
3. 📖 Próximo: Leia [DEVSECOPS.md](DEVSECOPS.md) para aprofundar
4. 🔒 Adicionar mais segurança (Network Policies, Pod Security Policy)
5. 📊 Monitoramento (Prometheus + Grafana)

---

## Links Úteis

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Trivy GitHub Action](https://aquasecurity.github.io/trivy/latest/integrations/github-actions/)
- [Argo CD GitHub Integration](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/)
- [GHCR Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

---

## Placeholders Referência

| Placeholder | Exemplo | Onde Substitui |
|-------------|---------|-----------------|
| `[seu-usuario]` | `joao-silva` | GitHub username |
| `[seu-token-github]` | `ghp_xxxx...` | GitHub PAT |
| `[seu-caminho-pasta-projeto]` | `C:\Users\joao\Projects\lab1` | Caminho local |
| `lab1-devsecops-platform` | (manter igual) | Nome do repositório |

---

**CI/CD automático configurado! Próximo: [DEVSECOPS.md](DEVSECOPS.md)** 🚀
