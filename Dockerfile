# Stage 1: Builder
FROM python:3.12-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
# Instala diretamente no prefixo do sistema do builder
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Runtime
FROM python:3.12-slim

RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copia os pacotes instalados direto para os diretórios globais do Python
COPY --from=builder /install /usr/local
COPY src/main.py .

RUN chown -R appuser:appuser /app

LABEL maintainer="DevSecOps Lab"
LABEL version="1.0.0"

ENV PYTHONUNBUFFERED=1
ENV APP_VERSION=1.0.0

# Healthcheck via Python, sem depender de curl instalado na imagem
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

USER appuser

EXPOSE 5000

CMD ["python", "main.py"]