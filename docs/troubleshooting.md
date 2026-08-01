# Troubleshooting - Solução de Problemas

Guia completo para resolver problemas comuns no laboratório DevSecOps.

---

## Índice de Problemas

### Vagrant & VM
- [VM não inicializa](#vm-não-inicializa)
- [Timeout na inicialização](#timeout-na-inicialização)
- [Erro de SSH](#erro-de-ssh)
- [Docker permission denied](#docker-permission-denied)

### Kubernetes
- [Cluster Kind não responde](#cluster-kind-não-responde)
- [Pods em CrashLoopBackOff](#pods-em-crashloopbackoff)
- [Node não pronto](#node-não-pronto)
- [Saída de memória/CPU](#saída-de-memóriacpu)

### Argo CD
- [Argo CD não sincroniza](#argo-cd-não-sincroniza)
- [Application em OutOfSync](#application-em-outofsync)
- [Erro de autenticação](#erro-de-autenticação)
- [Webhook não funciona](#webhook-não-funciona)

### GitHub Actions
- [Pipeline falhando no Trivy](#pipeline-falhando-no-trivy)
- [Build falha (Docker)](#build-falha-docker)
- [Push para registry falhando](#push-para-registry-falhando)

### Segurança
- [Vulnerabilidades críticas detectadas](#vulnerabilidades-críticas-detectadas)
- [Network policy bloqueando tráfego](#network-policy-bloqueando-tráfego)

### Rede & Conectividade
- [Porta 8080 já está em uso](#porta-8080-já-está-em-uso)
- [Localhost não responde](#localhost-não-responde)
- [WSL não consegue acessar VM](#wsl-não-consegue-acessar-vm)

---

# 🔧 VAGRANT & VM

## VM não inicializa

### ❌ Erro
```
Vagrant failed to initialize at a very early stage
```

### ✅ Solução

**1. Verificar VirtualBox**
```bash
VBoxManage --version
# Se não funcionar, reinstalar VirtualBox
```

**2. Limpar estado**
```bash
vagrant destroy
vagrant box update
vagrant up
```

**3. Aumentar timeout**
```ruby
# No Vagrantfile
config.vm.boot_timeout = 900  # 15 minutos
```

**4. Reduzir recursos**
```ruby
# Se PC é lento
config.vm.provider "virtualbox" do |vb|
  vb.memory = "2048"  # De 4096 para 2048
  vb.cpus = 1         # De 2 para 1
end
```

**5. Verificar espaço em disco**
```bash
# Precisa de pelo menos 20GB livres
```

---

## Timeout na inicialização

### ❌ Erro
```
Timed out while waiting for the machine to boot
```

### ✅ Solução

**1. Aumentar boot timeout**
```ruby
config.vm.boot_timeout = 600  # Mude para 900 (15 min)
```

**2. Verificar se VirtualBox está funcionando**
- Abra VirtualBox GUI no Windows
- Veja se a VM está inicializando
- Se preta (bootando) → deixar rodar
- Se sem movimento → destruir e tentar novamente

**3. Verificar logs**
```bash
# No VirtualBox GUI
# VM → Detalhes → Ver logs
```

**4. Tentar novamente**
```bash
vagrant destroy
vagrant up
```

---

## Erro de SSH

### ❌ Erro
```
timeout during server version negotiating
```

### ✅ Solução

**1. Aumentar SSH timeout**
```ruby
config.ssh.connect_timeout = 120  # Aumentar de 60
```

**2. Parar SSH agent do Windows**
```powershell
# PowerShell como Admin
Stop-Service ssh-agent -Force
Set-Service ssh-agent -StartupType Disabled
```

**3. Usar insert_key = false**
```ruby
config.ssh.insert_key = false
```

**4. Destruir e recriar**
```bash
vagrant destroy
vagrant up
```

---

## Docker permission denied

### ❌ Erro
```
permission denied while trying to connect to the docker API
```

### ✅ Solução

**Na VM (vagrant ssh):**

```bash
# 1. Verificar se docker está rodando
sudo service docker status

# 2. Iniciar docker
sudo service docker start

# 3. Adicionar vagrant ao grupo docker
sudo usermod -aG docker vagrant

# 4. Ativar sem fazer logout
newgrp docker

# 5. Testar
docker ps
```

**Se ainda não funcionar:**

```bash
# Tentar com sudo
sudo docker ps

# Se funciona com sudo mas não sem:
sudo chown $USER /var/run/docker.sock
```

---

# KUBERNETES

## Cluster Kind não responde

### ❌ Erro
```
error: Unable to connect to the server
```

### ✅ Solução

**1. Verificar se o container está rodando**
```bash
docker ps | grep kind
# Deve ver: kindest/node:v1.30.0
```

**2. Se não estiver, recriar cluster**
```bash
kind delete cluster --name lab1-cluster
kind create cluster --name lab1-cluster --config /tmp/kind-config.yaml
```

**3. Configurar kubeconfig**
```bash
kind get kubeconfig --name lab1-cluster > $HOME/.kube/config
chmod 600 $HOME/.kube/config
```

**4. Testar conexão**
```bash
kubectl cluster-info
kubectl get nodes
```

---

## Pods em CrashLoopBackOff

### ❌ Erro
```
hello-api   0/1     CrashLoopBackOff
```

### ✅ Solução

**1. Ver logs**
```bash
kubectl logs deployment/hello-api
# Ver última linha de erro
```

**2. Descrever pod**
```bash
kubectl describe pod <pod-name>
# Ver seção "Events"
```

**3. Causas comuns**

**Imagem não encontrada:**
```bash
# Verificar se imagem existe
docker images | grep hello-api

# Se não existe, fazer build
docker build -t hello-api:v1 apps/hello-api/
```

**Porta já em uso:**
```bash
# Mudar porta no deployment.yaml
# containerPort: 5000 (já é a padrão, OK)
```

**Dependências faltando:**
```bash
# Verificar requirements.txt
cat apps/hello-api/requirements.txt

# Instalar dependências
pip install -r apps/hello-api/requirements.txt
```

**4. Reiniciar deployment**
```bash
kubectl rollout restart deployment/hello-api
kubectl rollout status deployment/hello-api
```

---

## Node não pronto

### ❌ Erro
```
kubectl get nodes
# Status: NotReady
```

### ✅ Solução

```bash
# 1. Verificar logs do node
kubectl describe node <node-name>

# 2. Ver CNI (network plugin)
kubectl get pods -n kube-system

# 3. Se kubelet está rodando
docker ps | grep kubelet

# 4. Recriar cluster
kind delete cluster --name lab1-cluster
kind create cluster --name lab1-cluster
```

---

## Saída de memória/CPU

### ❌ Erro
```
Pod evicted
OOMKilled
```

### ✅ Solução

**1. Ver uso de recursos**
```bash
kubectl top nodes
kubectl top pods
```

**2. Aumentar memória na VM**

No Vagrantfile:
```ruby
config.vm.provider "virtualbox" do |vb|
  vb.memory = "8192"  # Aumentar para 8GB
  vb.cpus = 4         # Aumentar para 4 CPUs
end
```

**3. Reduzir replicas**
```bash
kubectl scale deployment hello-api --replicas=1
```

**4. Aumentar limits no deployment**
```yaml
resources:
  limits:
    memory: "256Mi"
    cpu: "500m"
```

---

# ARGO CD

## Argo CD não sincroniza

### ❌ Erro
```
argocd app get hello-api
# Status: OutOfSync
```

### ✅ Solução

**1. Forçar sincronização**
```bash
argocd app sync hello-api --force
```

**2. Ver status detalhado**
```bash
argocd app get hello-api
# Procurar por erro na seção "Details"
```

**3. Ver logs**
```bash
# Logs do Argo CD
kubectl logs -f deployment/argocd-server -n argocd

# Logs da aplicação
kubectl logs -f deployment/argocd-application-controller -n argocd
```

**4. Verificar repositório**
```bash
# Argo CD consegue acessar o repositório?
argocd repo list

# Se houver erro, reconectar
argocd repo add https://seu-repo --force-https
```

**5. Verificar permissões**
```bash
# Ter acesso de leitura ao repositório
# GitHub → Settings → Deploy keys
```

---

## Application em OutOfSync

### ❌ Erro
```
Status: OutOfSync
```

### ✅ Solução

**1. Verificar o que está diferente**
```bash
argocd app diff hello-api
```

**2. Sincronizar**
```bash
argocd app sync hello-api
```

**3. Habilitar sincronização automática**
```bash
argocd app set hello-api --sync-policy auto --auto-prune --self-heal
```

**4. Se estiver preso**
```bash
# Deletar e recriar application
argocd app delete hello-api
argocd app create hello-api \
  --repo https://seu-repo \
  --path apps/hello-api/k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
```

---

## Erro de autenticação

### ❌ Erro
```
authentication required
unable to authenticate
```

### ✅ Solução

**1. Verificar credenciais**
```bash
argocd repo list
# Ver status de cada repo
```

**2. Atualizar credenciais**
```bash
argocd repo remove https://seu-repo
argocd repo add https://seu-repo \
  --username seu-usuario \
  --password seu-token
```

**3. Usar token pessoal do GitHub**
```bash
# GitHub → Settings → Developer settings → Personal access tokens
# Scopes: repo, write:packages
```

**4. Verificar deploy keys**
```bash
# Se usando SSH
# GitHub → Settings → Deploy keys
# Adicionar chave pública do cluster
```

---

## Webhook não funciona

### ❌ Erro
```
Argo CD não sincroniza quando há git push
```

### ✅ Solução

**1. Habilitar sincronização automática**
```bash
argocd app set hello-api --sync-policy auto
```

**2. Configurar webhook no GitHub**
- GitHub → Repositório → Settings → Webhooks
- Add webhook
- Payload URL: `http://seu-dominio/api/webhook`
- Content type: `application/json`
- Eventos: `push`

**3. Verificar se webhook está funcionando**
```bash
# GitHub → Webhooks → Ver últimas entregas
```

**4. Aumentar polling interval (alternativa)**
```bash
# Se webhook não funcionar, Argo CD faz polling
argocd app set hello-api --controller-replicas 1
```

---

# GITHUB ACTIONS

## Pipeline falhando no Trivy

### ❌ Erro (no GitHub Actions)
```
Run Trivy scan
Vulnerabilities found: CRITICAL
```

### ✅ Solução

**1. Verificar vulnerabilidades localmente**
```bash
docker build -t hello-api:v1 apps/hello-api/
trivy image hello-api:v1
```

**2. Tipos de vulns**
- CRITICAL → ❌ Falha (não faz deploy)
- HIGH → ⚠️ Aviso (pode continuar)
- MEDIUM → ℹ️ Info

**3. Resolver vulnerabilidades**

**Vulnerabilidade em dependência:**
```bash
# Atualizar pip/npm
pip install --upgrade pip
pip install --upgrade -r requirements.txt

# Ou atualizar versão específica
# requirements.txt
Flask==3.0.1  # (de 3.0.0)
```

**Vulnerabilidade em camada base:**
```dockerfile
# Use imagem atualizada
FROM python:3.12-slim  # Verificar latest
```

**4. Contornar (último recurso)**
```yaml
# No ci.yml, mudar exit-code
trivy image --exit-code 0 hello-api:v1  # Aviso, não falha
```

**5. Testar localmente antes do push**
```bash
trivy image --severity CRITICAL,HIGH hello-api:v1
```

---

## Build falha (Docker)

### ❌ Erro
```
docker build failed
```

### ✅ Solução

**1. Testar build localmente**
```bash
docker build -t hello-api:test apps/hello-api/
```

**2. Verificar Dockerfile**
```bash
# Ver erros no Dockerfile
docker build -t hello-api:test --progress=plain apps/hello-api/
```

**3. Erros comuns**

**Arquivo não encontrado:**
```dockerfile
# Verificar COPY
COPY requirements.txt .
# O arquivo existe? Checar caminho
```

**Comando não encontrado:**
```dockerfile
# RUN pip install...
# pip está disponível nesta imagem?
FROM python:3.12-slim  # Sim
FROM alpine:latest     # Não (instalar)
```

**Permissão negada:**
```bash
# Verificar permissões dos arquivos
chmod +x apps/hello-api/src/main.py
```

---

## Push para registry falhando

### ❌ Erro
```
unauthorized: authentication required
```

### ✅ Solução

**1. Se usar GHCR (GitHub Container Registry)**
- Automático, usa `GITHUB_TOKEN`
- Verificar token tem permissão `write:packages`

**2. Se usar Docker Hub**
```yaml
# No GitHub Secrets adicionar:
DOCKER_USERNAME = seu-usuario
DOCKER_PASSWORD = seu-token
```

**3. Se usar registry privado**
```yaml
# Login no ci.yml
- name: Login to Registry
  run: |
    echo ${{ secrets.REGISTRY_PASSWORD }} | \
    docker login -u ${{ secrets.REGISTRY_USER }} --password-stdin seu-registry.com
```

**4. Testar login localmente**
```bash
# GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u seu-usuario --password-stdin

# Docker Hub
docker login
```

---

# SEGURANÇA

## Vulnerabilidades críticas detectadas

### ❌ Erro
```
Trivy detected CRITICAL vulnerabilities
```

### ✅ Solução

**Passo 1: Identificar qual dependência**
```bash
trivy image --format json hello-api:v1 | jq '.Results[] | select(.Severity=="CRITICAL")'
```

**Passo 2: Atualizar dependência**
```bash
# Python
pip install --upgrade flask

# Node
npm audit fix
npm audit fix --force
```

**Passo 3: Verificar versão segura**
```bash
# Procurar CVE no NVD
# https://nvd.nist.gov/
```

**Passo 4: Testar antes de committar**
```bash
docker build -t hello-api:test .
trivy image hello-api:test
```

**Passo 5: Se vulnerabilidade do SO**
```dockerfile
# Atualizar imagem base
FROM python:3.12.0-slim  # Mais recente
# ou
RUN apt-get update && apt-get upgrade -y
```

---

## Network policy bloqueando tráfego

### ❌ Erro
```
Connection refused
Network policy blocking
```

### ✅ Solução

**1. Verificar network policies**
```bash
kubectl get networkpolicy -A
kubectl describe networkpolicy hello-api-netpol
```

**2. Temporariamente desabilitar**
```bash
kubectl delete networkpolicy hello-api-netpol
```

**3. Testar conexão**
```bash
kubectl logs -f deployment/hello-api
```

**4. Se funcionar sem policy**
- Revisar as rules da policy
- Adicionar ingress/egress correto
- Reapliar policy

**5. Exemplo de policy corrigida**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: hello-api-netpol
spec:
  podSelector:
    matchLabels:
      app: hello-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector: {}  # Permite de qualquer namespace
      podSelector:
        matchLabels:
          app: hello-api
  egress:
  - to:
    - namespaceSelector: {}
```

---

# REDE & CONECTIVIDADE

## Porta 8080 já está em uso

### ❌ Erro
```
Port 8080 is already in use
```

### ✅ Solução

**1. Identificar processo usando porta**
```bash
# Windows
netstat -ano | findstr :8080

# Linux/WSL
lsof -i :8080
ss -tulpn | grep 8080
```

**2. Matar processo (opcional)**
```bash
# Windows
taskkill /PID <PID> /F

# Linux
kill -9 <PID>
```

**3. Mudar porta no Vagrantfile**
```ruby
config.vm.network "forwarded_port", guest: 8080, host: 8888
# Acessar em: http://localhost:8888
```

**4. Mudar porta no deployment**
```yaml
ports:
- containerPort: 5000  # Porta interna do container
```

```bash
# Service NodePort
kubectl patch svc hello-api -p '{"spec":{"ports":[{"port":80,"targetPort":5000,"nodePort":30089}]}}'
```

---

## Localhost não responde

### ❌ Erro
```
http://localhost:8080 não funciona
connection refused
```

### ✅ Solução

**1. Verificar se serviço está rodando**
```bash
vagrant ssh
kubectl get svc
# hello-api deve estar lá
```

**2. Verificar se porta está mapeada**
```bash
kubectl get svc hello-api -o wide
# Procurar por 80:30080
```

**3. Acessar diretamente pela NodePort**
```bash
# Via WSL/VM
curl http://localhost:30080/health

# Ou via IP do nó
kubectl get nodes -o wide
# Copiar IP INTERNAL
curl http://<IP>:30080/health
```

**4. Port forwarding (alternativa)**
```bash
kubectl port-forward svc/hello-api 8080:80 &
# Agora acessa em http://localhost:8080
```

**5. Verificar firewall**
```bash
# Windows
# Painel de Controle → Firewall → Permitir app
# Adicionar VirtualBox
```

---

## WSL não consegue acessar VM

### ❌ Erro
```
vagrant ssh não funciona de dentro do WSL
```

### ✅ Solução

**1. Use o caminho correto**
```bash
cd /mnt/c/Users/nelson.pires/Documents/Labs/lab1-devsecops-platform
vagrant ssh
```

**2. Verifique vagrant está no PATH (WSL)**
```bash
# No WSL
which vagrant

# Se não existe:
alias vagrant="/mnt/c/Program\ Files/Vagrant/bin/vagrant.exe"
```

**3. Use Vagrant do Windows**
```bash
# Dentro da VM (via WSL com alias)
vagrant ssh

# Ou use diretamente
/mnt/c/Program\ Files/Vagrant/bin/vagrant.exe ssh
```

---

# DEBUG AVANÇADO

## Verificar tudo de uma vez

```bash
# Checklist completo
vagrant status
VBoxManage --version
vagrant ssh

# Dentro da VM
docker ps
kubectl get nodes
kubectl get pods -A
argocd app list
argocd app get hello-api

# Conectividade
curl http://localhost:8080/health
curl http://localhost:8080/api/info
```

## Capturar logs completos

```bash
# Todos os logs
kubectl logs -n argocd deployment/argocd-server > logs-argocd.txt
kubectl logs deployment/hello-api > logs-app.txt
kubectl describe pod <pod-name> > pod-details.txt

# Eventos do cluster
kubectl get events -A --sort-by='.lastTimestamp' > events.txt
```

## Resetar tudo

```bash
# Nuclear option - começa do zero
vagrant destroy
rm -rf .vagrant

# Depois
vagrant up
```

---

# Ainda não funciona?

## Próximas ações

1. **Coletar logs**
   ```bash
   kubectl logs deployment/hello-api > app.log
   kubectl logs -n argocd deployment/argocd-server > argo.log
   ```

2. **Descrever recursos**
   ```bash
   kubectl describe deployment/hello-api > deployment.log
   kubectl describe pod <pod-name> > pod.log
   ```

3. **Verificar eventos**
   ```bash
   kubectl get events -A --sort-by='.lastTimestamp'
   ```

4. **Checklist**
   - Vagrant up completou sem erros?
   - Cluster está pronto? (`kubectl get nodes`)
   - Pods estão rodando? (`kubectl get pods`)
   - Argo CD está online? (`argocd app list`)
   - Aplicação responde? (`curl http://localhost:8080/health`)

5. **Documentação**
   - [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster/)
   - [Argo CD Troubleshooting](https://argo-cd.readthedocs.io/en/stable/faq/)
   - [Trivy Documentation](https://aquasecurity.github.io/trivy/)

---

**Sucesso! Seu problema deve estar resolvido! 🎉**
