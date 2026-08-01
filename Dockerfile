# Stage 1: Builder
FROM python:3.12-slim as builder

WORKDIR /app

# Instalar dependências de compilação
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements e instalar no diretório do usuário
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Runtime (imagem final)
FROM python:3.12-slim

# Instalar curl apenas para o HEALTHCHECK do Docker
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Criar usuário não-root
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copiar bibliotecas compiladas do builder
COPY --from=builder /root/.local /home/appuser/.local

# CORREÇÃO 1: Copiar o main.py de dentro da pasta src/
COPY src/main.py .

# Ajustar permissões da pasta para o usuário não-root
RUN chown -R appuser:appuser /app /home/appuser/.local

# Metadados
LABEL maintainer="DevSecOps Lab"
LABEL version="1.0.0"
LABEL description="Hello API - DevSecOps Example"

# Variáveis de ambiente
ENV PATH=/home/appuser/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1
ENV APP_VERSION=1.0.0

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Mudar para usuário não-root
USER appuser

# Expor porta
EXPOSE 5000

# Entrypoint
CMD ["python", "main.py"]