#!/bin/bash
set -e

# Script de configuración de Google Antigravity
# Uso: ./scripts/03_setup-antigravity.sh

echo "🌌 Configurando integración con Google Antigravity..."

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar que .env existe y tiene las credenciales
if [ ! -f .env ]; then
    echo -e "${RED}❌ Error: Archivo .env no encontrado${NC}"
    exit 1
fi

source .env

if [ -z "$GOOGLE_ANTIGRAVITY_API_KEY" ] || [ "$GOOGLE_ANTIGRAVITY_API_KEY" == "REPLACE_ME" ]; then
    echo -e "${RED}❌ Error: GOOGLE_ANTIGRAVITY_API_KEY no configurada en .env${NC}"
    exit 1
fi

if [ -z "$GOOGLE_ANTIGRAVITY_PROJECT_ID" ] || [ "$GOOGLE_ANTIGRAVITY_PROJECT_ID" == "REPLACE_ME" ]; then
    echo -e "${RED}❌ Error: GOOGLE_ANTIGRAVITY_PROJECT_ID no configurado en .env${NC}"
    exit 1
fi

echo -e "${BLUE}🔑 API Key: ${GOOGLE_ANTIGRAVITY_API_KEY:0:20}...${NC}"
echo -e "${BLUE}📦 Project ID: ${GOOGLE_ANTIGRAVITY_PROJECT_ID}${NC}"

# Crear directorio de configuración
mkdir -p .local/antigravity

# Crear archivo de configuración de Antigravity
cat > .local/antigravity/config.json <<EOF
{
  "api_key": "${GOOGLE_ANTIGRAVITY_API_KEY}",
  "project_id": "${GOOGLE_ANTIGRAVITY_PROJECT_ID}",
  "workspace_id": "${SESSION_ID:-default}",
  "sync_enabled": true,
  "sync_interval": 300,
  "features": {
    "code_completion": true,
    "code_generation": true,
    "code_review": true,
    "context_aware": true,
    "agent_collaboration": true
  },
  "webhooks": {
    "on_code_change": "",
    "on_agent_decision": "",
    "on_hitl_checkpoint": ""
  }
}
EOF

echo -e "${GREEN}✅ Configuración de Antigravity creada${NC}"

# Crear cliente Python para Antigravity
cat > src/utils/antigravity_client.py <<'PYEOF'
"""
Cliente para integración con Google Antigravity IDE
"""
import os
import json
import requests
from typing import Dict, Any, Optional, List
from loguru import logger


class AntigravityClient:
    """Cliente para interactuar con Google Antigravity API"""
    
    def __init__(self):
        self.api_key = os.getenv("GOOGLE_ANTIGRAVITY_API_KEY")
        self.project_id = os.getenv("GOOGLE_ANTIGRAVITY_PROJECT_ID")
        self.base_url = "https://antigravity.googleapis.com/v1"
        
        if not self.api_key or not self.project_id:
            raise ValueError("Credenciales de Antigravity no configuradas")
        
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "X-Project-ID": self.project_id
        }
    
    def sync_context(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Sincronizar contexto con Antigravity"""
        try:
            response = requests.post(
                f"{self.base_url}/context/sync",
                headers=self.headers,
                json=context,
                timeout=30
            )
            response.raise_for_status()
            logger.info("Contexto sincronizado con Antigravity")
            return response.json()
        except Exception as e:
            logger.error(f"Error sincronizando contexto: {e}")
            return {"error": str(e)}
    
    def get_code_suggestions(
        self, 
        code: str, 
        language: str,
        context: Optional[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """Obtener sugerencias de código"""
        try:
            payload = {
                "code": code,
                "language": language,
                "context": context or {}
            }
            response = requests.post(
                f"{self.base_url}/code/suggestions",
                headers=self.headers,
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            return response.json().get("suggestions", [])
        except Exception as e:
            logger.error(f"Error obteniendo sugerencias: {e}")
            return []
    
    def generate_code(
        self,
        prompt: str,
        language: str,
        context: Optional[Dict[str, Any]] = None
    ) -> str:
        """Generar código desde prompt"""
        try:
            payload = {
                "prompt": prompt,
                "language": language,
                "context": context or {}
            }
            response = requests.post(
                f"{self.base_url}/code/generate",
                headers=self.headers,
                json=payload,
                timeout=60
            )
            response.raise_for_status()
            return response.json().get("code", "")
        except Exception as e:
            logger.error(f"Error generando código: {e}")
            return ""
    
    def review_code(
        self,
        code: str,
        language: str,
        context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Revisar código y obtener feedback"""
        try:
            payload = {
                "code": code,
                "language": language,
                "context": context or {}
            }
            response = requests.post(
                f"{self.base_url}/code/review",
                headers=self.headers,
                json=payload,
                timeout=60
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Error revisando código: {e}")
            return {"error": str(e)}
    
    def notify_agent_decision(
        self,
        agent_name: str,
        decision: str,
        context: Dict[str, Any]
    ) -> bool:
        """Notificar decisión de agente a Antigravity"""
        try:
            payload = {
                "agent_name": agent_name,
                "decision": decision,
                "context": context,
                "timestamp": context.get("timestamp")
            }
            response = requests.post(
                f"{self.base_url}/agents/decision",
                headers=self.headers,
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            logger.info(f"Decisión de {agent_name} notificada a Antigravity")
            return True
        except Exception as e:
            logger.error(f"Error notificando decisión: {e}")
            return False


# Singleton instance
_client: Optional[AntigravityClient] = None


def get_antigravity_client() -> AntigravityClient:
    """Obtener instancia singleton del cliente"""
    global _client
    if _client is None:
        _client = AntigravityClient()
    return _client
PYEOF

echo -e "${GREEN}✅ Cliente Python de Antigravity creado${NC}"

# Crear script de prueba
cat > .local/antigravity/test_connection.py <<'PYEOF'
#!/usr/bin/env python3
"""
Script de prueba para verificar conexión con Antigravity
"""
import sys
sys.path.insert(0, '/workspace')

from src.utils.antigravity_client import get_antigravity_client
from loguru import logger

def main():
    logger.info("Probando conexión con Google Antigravity...")
    
    try:
        client = get_antigravity_client()
        logger.success("✅ Cliente inicializado correctamente")
        
        # Test sync context
        test_context = {
            "project": "test",
            "type": "connection_test",
            "timestamp": "2024-01-01T00:00:00Z"
        }
        
        result = client.sync_context(test_context)
        if "error" not in result:
            logger.success("✅ Sincronización de contexto exitosa")
        else:
            logger.error(f"❌ Error en sincronización: {result['error']}")
        
        logger.info("Prueba completada")
        
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
PYEOF

chmod +x .local/antigravity/test_connection.py

echo -e "${GREEN}✅ Script de prueba creado${NC}"
echo ""
echo -e "${BLUE}Para probar la conexión:${NC}"
echo "docker compose exec dev python .local/antigravity/test_connection.py"
echo ""
echo -e "${GREEN}🎉 Configuración de Antigravity completada!${NC}"
