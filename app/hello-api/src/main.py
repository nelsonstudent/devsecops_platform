#!/usr/bin/env python3
"""
Hello API - DevSecOps Example Application
Uma API REST simples para demonstrar o fluxo GitOps + Segurança
"""

from flask import Flask, jsonify
import os
from datetime import datetime

app = Flask(__name__)

# Configurações
VERSION = os.getenv("APP_VERSION", "1.0.0")
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": VERSION
    }), 200

@app.route('/api/info', methods=['GET'])
def info():
    """Informações da aplicação"""
    return jsonify({
        "app": "hello-api",
        "version": VERSION,
        "environment": ENVIRONMENT,
        "timestamp": datetime.utcnow().isoformat()
    }), 200

@app.route('/api/hello', methods=['GET'])
def hello():
    """Endpoint simples"""
    return jsonify({
        "message": "Hello from DevSecOps Lab!",
        "version": VERSION
    }), 200

@app.route('/metrics', methods=['GET'])
def metrics():
    """Endpoint de métricas simples"""
    return jsonify({
        "requests": 0,
        "errors": 0,
        "uptime": "running"
    }), 200

@app.errorhandler(404)
def not_found(error):
    """404 handler"""
    return jsonify({
        "error": "Not Found",
        "message": "Endpoint não existe"
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """500 handler"""
    return jsonify({
        "error": "Internal Server Error",
        "message": "Erro interno do servidor"
    }), 500

if __name__ == '__main__':
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=ENVIRONMENT == 'development'
    )
