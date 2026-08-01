# Lab: DevSecOps & Platform Engineering

Uma plataforma completa de entrega contínua com **security-first** usando Kubernetes, Argo CD, GitHub Actions e Trivy.

## Quick Start

```bash
# Iniciar o laboratório (25-30 minutos na primeira vez)
cd [caminho-para-seu-projeto]
vagrant up

# Conectar à VM (via WSL)
vagrant ssh

# Acessar Argo CD
# URL: http://localhost:8080
# User: admin
# Pass: (exibido ao final do vagrant up)

# Testar aplicação
curl http://localhost:8080/health
```

**Substituir `[caminho-para-seu-projeto]` pelo seu caminho local:**
- Windows: `C:\Users\[seu-usuario]\Documents\Lab\lab1-devsecops-platform`
- Mac/Linux: `/Users/[seu-usuario]/Projects/lab1-devsecops-platform`

---

## Documentação

**Leia nesta ordem:**

| # | Arquivo | Propósito | Tempo |
|---|---------|----------|-------|
| 1 | [COMO-COMECAR.md](docs/COMO-COMECAR.md) | Setup inicial: estrutura de pastas, copiar arquivos, configurar Argo CD | 20 min |
| 2 | [QUICKSTART.md](docs/QUICKSTART.md) | Deploy da aplicação exemplo e testes básicos | 5 min |
| 3 | [DEVSECOPS.md](docs/DEVSECOPS.md) | Entender DevSecOps, GitOps e o fluxo completo | 30 min |
| 4 | [SETUP-GITHUB.md](docs/SETUP-GITHUB.md) | Configurar GitHub Actions, CI/CD e Argo CD com seu repositório | 30 min |
| 5 | [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Resolver problemas (quando algo não funciona) | On-demand |

---

## Arquitetura

```
Developer (git push)
    ↓
GitHub Actions (Build + Trivy Scan + Push)
    ↓
Container Registry (GHCR)
    ↓
Argo CD (Watch Git)
    ↓
Kubernetes (Deploy)
    ↓
Application LIVE ✅
```

---

## O que está incluído

- ✅ **Kubernetes** (Kind) - Cluster local em Docker
- ✅ **Argo CD** - GitOps: sincroniza Git com cluster
- ✅ **GitHub Actions** - CI/CD: build, scan, push
- ✅ **Trivy** - Scanning de vulnerabilidades
- ✅ **hello-api** - Aplicação exemplo (Python Flask)
- ✅ **Documentação completa** - 5 guias focados

---

## Estrutura do Projeto

```
lab1-devsecops-platform/
├── README.md                          ← Este arquivo
├── Vagrantfile                        ← Configuração VM
├── .gitignore
│
├── scripts/                           ← Provisioning (Vagrant)
│   ├── 01-install-tools.sh           # Docker, kubectl, Helm, Kind, Trivy
│   ├── 02-setup-kind.sh              # Kubernetes cluster
│   └── 03-deploy-cncf-stack.sh       # Argo CD
│
├── apps/hello-api/                    ← Aplicação exemplo
│   ├── src/main.py                    # Código Flask
│   ├── requirements.txt               # Dependências
│   ├── Dockerfile                     # Build (multi-stage)
│   └── k8s/
│       ├── deployment.yaml            # Kubernetes Deployment
│       ├── service.yaml               # NodePort (8080)
│       ├── serviceaccount.yaml        # RBAC
│       └── argocd-app.yaml            # GitOps Application
│
├── .github/workflows/                 ← CI/CD
│   └── ci.yml                         # GitHub Actions pipeline
│
└── docs/                              ← Documentação
    ├── COMO-COMECAR.md                # [Leia 1º] Setup inicial
    ├── QUICKSTART.md                  # [Leia 2º] 5 minutos
    ├── DEVSECOPS.md                   # [Leia 3º] Conceitos
    ├── SETUP-GITHUB.md                # [Leia 4º] GitHub + CI/CD
    └── TROUBLESHOOTING.md             # [Consulte] Problemas
```

---

## Links Importantes

| Recurso | URL |
|---------|-----|
| **Argo CD Dashboard** | http://localhost:8080 |
| **Aplicação (Health)** | http://localhost:8080/health |
| **Aplicação (Info)** | http://localhost:8080/api/info |

---

## Comandos Essenciais

```bash
# Vagrant
vagrant up              # Iniciar
vagrant ssh             # Conectar
vagrant halt            # Parar
vagrant destroy         # Destruir

# Kubernetes
kubectl get nodes       # Ver nós
kubectl get pods        # Ver pods
kubectl logs -f deployment/hello-api  # Logs

# Argo CD
argocd app list         # Listar apps
argocd app get hello-api  # Detalhes
argocd app sync hello-api  # Forçar sync
```

---

## Tech Stack

- **Orquestração:** Kubernetes (Kind)
- **Deployment:** Argo CD (GitOps)
- **CI/CD:** GitHub Actions
- **Segurança:** Trivy, Security Context, RBAC, Network Policies
- **Aplicação:** Python Flask
- **Containerização:** Docker (multi-stage)
- **Infraestrutura:** Vagrant + VirtualBox

---

## Próximas Etapas

Depois que tudo estiver funcionando:

1. Adicione mais aplicações (além do hello-api)
2. Configure GitHub Actions (build + deploy automático)
3. Implemente Network Policies
4. Adicione monitoramento (Prometheus + Grafana)
5. Integre Kyverno (policy enforcement)

---

## Precisa de Ajuda?

- **Primeira vez?** → Leia [COMO-COMECAR.md](docs/COMO-COMECAR.md)
- **Quer começar rápido?** → Leia [QUICKSTART.md](docs/QUICKSTART.md)
- **Tem um problema?** → Consulte [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- **Quer aprender?** → Leia [DEVSECOPS.md](docs/DEVSECOPS.md)

---

## Licença

MIT License - Use livremente para fins educacionais

---

**Created for learning DevSecOps & Platform Engineering** 🚀
