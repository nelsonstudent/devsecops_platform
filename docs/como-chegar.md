# Como Começar - Setup Local

Guia passo a passo para organizar o projeto e configurar o Argo CD pela primeira vez.

> **Nota:** Este guia usa caminhos variáveis. Substitua `[seu-caminho]` pelo caminho real no seu sistema.

---

## Pré-requisitos

- ✅ `vagrant up` já foi executado e completou
- ✅ VM está rodando e acessível
- ✅ Argo CD está online (http://localhost:8080)
- ✅ Cluster Kubernetes está pronto

---

## 1️⃣ Preparar Estrutura Local

No seu computador (não em WSL/VM):

### Windows

```bash
cd C:\Users\[seu-usuario]\[seu-caminho-pasta-projeto]

# Ou se preferir usar alias/variável:
cd $env:USERPROFILE\[seu-caminho-pasta-projeto]
```

### Mac/Linux

```bash
cd ~/[seu-caminho-pasta-projeto]
# ou
cd /Users/[seu-usuario]/[seu-caminho-pasta-projeto]
```

### Criar pastas

```bash
# Windows (PowerShell ou CMD)
mkdir -p apps\hello-api\src
mkdir -p apps\hello-api\k8s
mkdir -p .github\workflows
mkdir -p docs

# Mac/Linux
mkdir -p apps/hello-api/src
mkdir -p apps/hello-api/k8s
mkdir -p .github/workflows
mkdir -p docs
```

---

## 2️⃣ Copiar Arquivos

Copie os arquivos dos outputs para as pastas:

| De | Para |
|----|------|
| `app-main.py`              | `apps/hello-api/src/main.py` |
| `app-requirements.txt`     | `apps/hello-api/requirements.txt` |
| `app-Dockerfile`           | `apps/hello-api/Dockerfile` |
| `k8s-deployment.yaml`      | `apps/hello-api/k8s/deployment.yaml` |
| `k8s-service.yaml`         | `apps/hello-api/k8s/service.yaml` |
| `k8s-serviceaccount.yaml`  | `apps/hello-api/k8s/serviceaccount.yaml` |
| `argocd-app.yaml`          | `apps/hello-api/k8s/argocd-app.yaml` |
| `README.md`                | `README.md` |
| `QUICKSTART.md`            | `docs/QUICKSTART.md` |
| `DEVSECOPS.md`             | `docs/DEVSECOPS.md` |
| `SETUP-GITHUB.md`          | `docs/SETUP-GITHUB.md` |
| `TROUBLESHOOTING.md`       | `docs/TROUBLESHOOTING.md` |
| `github-actions-ci.yml`    | `.github/workflows/ci.yml` |

---

## 3️⃣ Criar .gitignore

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
```

---

## 4️⃣ Ajustar URLs para seu Repositório

Edite `apps/hello-api/k8s/argocd-app.yaml`:

```yaml
# ANTES
spec:
  source:
    repoURL: https://github.com/seu-usuario/lab1-devsecops-platform

# DEPOIS - Use seu GitHub
spec:
  source:
    repoURL: https://github.com/[SEU-USUARIO]/lab1-devsecops-platform
```

**Substituir:**
- `[SEU-USUARIO]` → seu nome de usuário GitHub (ex: `joao-silva`)

---

## 5️⃣ Git Commit e Push

```bash
# Adicionar tudo
git add .

# Commit inicial
git commit -m "feat: add hello-api application and documentation"

# Push para main
git push origin main
```

---

## 6️⃣ Configurar Argo CD (Primeira Vez)

Dentro da VM:

```bash
vagrant ssh

# Adicionar seu repositório ao Argo CD
argocd repo add https://github.com/[SEU-USUARIO]/lab1-devsecops-platform \
  --username [SEU-USUARIO] \
  --password [SEU-TOKEN-GITHUB]

# Listar repos (verificar que foi adicionado)
argocd repo list
```

**Substituir:**
- `[SEU-USUARIO]` → seu nome de usuário GitHub
- `[SEU-TOKEN-GITHUB]` → seu personal access token

**Se não tiver token GitHub:**
1. Vá em: GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Scopes: `repo`, `write:packages`
4. Copie o token

---

## 7️⃣ Criar Application no Argo CD

Via CLI:

```bash
argocd app create hello-api \
  --repo https://github.com/[SEU-USUARIO]/lab1-devsecops-platform \
  --path apps/hello-api/k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy auto
```

**Substituir:**
- `[SEU-USUARIO]` → seu nome de usuário GitHub

Ou via UI (http://localhost:8080):
1. New App
2. **Nome:** hello-api
3. **Repository:** seu repositório
4. **Path:** apps/hello-api/k8s
5. **Destination Server:** https://kubernetes.default.svc
6. **Destination Namespace:** default
7. **Sync Policy:** Automatic
8. Create

---

## 8️⃣ Verificar Status

```bash
# Verificar que a app foi criada
argocd app list
argocd app get hello-api

# Deve mostrar: Synced ✅
```

---

## ✅ Checklist de Setup

- [ ] Pastas criadas (`apps/`, `docs/`, `.github/workflows/`)
- [ ] Arquivos copiados para os lugares certos
- [ ] `.gitignore` criado
- [ ] `argocd-app.yaml` editado com sua URL do GitHub
- [ ] Tudo commitado e pushed ao GitHub
- [ ] Repositório adicionado ao Argo CD (`argocd repo list`)
- [ ] Application criada (`argocd app get hello-api`)
- [ ] Status é "Synced" ✅

---

## Próximo Passo

1. ✅ **Você terminou este:** Setup local
2. 📖 **Próximo:** Leia [QUICKSTART.md](QUICKSTART.md) - Deploy e teste a aplicação

---

## Problemas?

- **"Repositório não adicionado"?** → Verificar token GitHub
- **"Application não sincroniza"?** → Ver [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **"Argo CD offline"?** → Executar `vagrant up` novamente

---

## Referência de Caminhos

| Sistema | Caminho Exemplo |
|---------|-----------------|
| **Windows** | `C:\Users\[seu-usuario]\Projects\lab1-devsecops-platform` |
| **Windows** | `C:\Users\[seu-usuario]\Documents\Labs\lab1-devsecops-platform` |
| **Mac** | `/Users/[seu-usuario]/Projects/lab1-devsecops-platform` |
| **Linux** | `/home/[seu-usuario]/Projects/lab1-devsecops-platform` |
| **Genérico** | `~/[seu-caminho-pasta-projeto]` |

---

**Setup completo! Próximo: [QUICKSTART.md](QUICKSTART.md)** 🚀
