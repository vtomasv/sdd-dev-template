#!/bin/bash
set -e

# Script de inicialización del sistema de auditoría
# Uso: ./scripts/04_audit-init.sh

echo "📊 Inicializando sistema de auditoría..."

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Crear directorio de logs
mkdir -p .local/audit/logs
mkdir -p .local/audit/reports

# Verificar conexión a base de datos
echo -e "${BLUE}🔍 Verificando conexión a PostgreSQL...${NC}"
python3 - <<'PYEOF'
import os
import psycopg

try:
    url = os.environ["DATABASE_URL"]
    with psycopg.connect(url) as conn:
        with conn.cursor() as cur:
            # Verificar tablas de auditoría
            cur.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name IN ('audit_log', 'hitl_checkpoints', 'dev_sessions')
            """)
            tables = [row[0] for row in cur.fetchall()]
            
            if len(tables) == 3:
                print("✅ Tablas de auditoría verificadas:", tables)
            else:
                print("⚠️  Faltan tablas de auditoría:", tables)
                
except Exception as e:
    print(f"❌ Error conectando a PostgreSQL: {e}")
    exit(1)
PYEOF

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Error verificando base de datos. Asegúrate de que PostgreSQL esté corriendo.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Base de datos verificada${NC}"

# Crear configuración de auditoría
cat > .local/audit/config.json <<EOF
{
  "enabled": true,
  "log_level": "${AUDIT_LOG_LEVEL:-INFO}",
  "database": {
    "enabled": ${AUDIT_DB_ENABLED:-true},
    "table": "audit_log"
  },
  "file": {
    "enabled": ${AUDIT_FILE_ENABLED:-true},
    "path": ".local/audit/logs",
    "rotation": "daily",
    "retention_days": 30
  },
  "tracking": {
    "agent_decisions": true,
    "code_changes": true,
    "hitl_checkpoints": true,
    "api_calls": true,
    "errors": true
  },
  "notifications": {
    "slack": {
      "enabled": false,
      "webhook": ""
    },
    "email": {
      "enabled": false,
      "recipients": []
    }
  }
}
EOF

echo -e "${GREEN}✅ Configuración de auditoría creada${NC}"

# Crear script de consulta de auditoría
cat > .local/audit/query_audit.sh <<'SHEOF'
#!/bin/bash
# Script para consultar logs de auditoría

case "$1" in
  recent)
    echo "📋 Últimas 20 entradas de auditoría:"
    docker compose exec -T postgres psql -U ${POSTGRES_USER:-sdd} -d ${POSTGRES_DB:-sdd} -c \
      "SELECT id, agent_name, action, timestamp FROM audit_log ORDER BY timestamp DESC LIMIT 20;"
    ;;
  
  by-agent)
    if [ -z "$2" ]; then
      echo "Uso: $0 by-agent <agent_name>"
      exit 1
    fi
    echo "📋 Entradas de auditoría para agente: $2"
    docker compose exec -T postgres psql -U ${POSTGRES_USER:-sdd} -d ${POSTGRES_DB:-sdd} -c \
      "SELECT id, action, decision, timestamp FROM audit_log WHERE agent_name = '$2' ORDER BY timestamp DESC LIMIT 20;"
    ;;
  
  hitl)
    echo "📋 Checkpoints HITL pendientes:"
    docker compose exec -T postgres psql -U ${POSTGRES_USER:-sdd} -d ${POSTGRES_DB:-sdd} -c \
      "SELECT id, checkpoint_name, agent_name, status, created_at FROM hitl_checkpoints WHERE status = 'pending' ORDER BY created_at DESC;"
    ;;
  
  sessions)
    echo "📋 Sesiones de desarrollo:"
    docker compose exec -T postgres psql -U ${POSTGRES_USER:-sdd} -d ${POSTGRES_DB:-sdd} -c \
      "SELECT session_id, project_type, status, started_at FROM dev_sessions ORDER BY started_at DESC LIMIT 10;"
    ;;
  
  stats)
    echo "📊 Estadísticas de auditoría:"
    docker compose exec -T postgres psql -U ${POSTGRES_USER:-sdd} -d ${POSTGRES_DB:-sdd} -c \
      "SELECT agent_name, COUNT(*) as decisions FROM audit_log GROUP BY agent_name ORDER BY decisions DESC;"
    ;;
  
  *)
    echo "Uso: $0 {recent|by-agent|hitl|sessions|stats}"
    echo ""
    echo "Comandos:"
    echo "  recent         - Mostrar últimas 20 entradas"
    echo "  by-agent NAME  - Mostrar entradas de un agente específico"
    echo "  hitl           - Mostrar checkpoints HITL pendientes"
    echo "  sessions       - Mostrar sesiones de desarrollo"
    echo "  stats          - Mostrar estadísticas de auditoría"
    exit 1
    ;;
esac
SHEOF

chmod +x .local/audit/query_audit.sh

echo -e "${GREEN}✅ Script de consulta creado: .local/audit/query_audit.sh${NC}"

# Insertar entrada de prueba
echo -e "${BLUE}🧪 Insertando entrada de prueba...${NC}"
python3 - <<'PYEOF'
import os
import psycopg
from datetime import datetime

try:
    url = os.environ["DATABASE_URL"]
    with psycopg.connect(url) as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO audit_log (
                    agent_name, 
                    action, 
                    decision, 
                    context, 
                    reasoning,
                    confidence,
                    session_id
                ) VALUES (
                    'system',
                    'audit_init',
                    'Sistema de auditoría inicializado correctamente',
                    '{"event": "init", "version": "1.0"}',
                    'Inicialización automática del sistema de auditoría',
                    1.0,
                    'system-init'
                )
            """)
            conn.commit()
            print("✅ Entrada de prueba insertada")
except Exception as e:
    print(f"❌ Error: {e}")
PYEOF

echo ""
echo -e "${GREEN}✅ Sistema de auditoría inicializado correctamente!${NC}"
echo ""
echo -e "${BLUE}Comandos útiles:${NC}"
echo "  .local/audit/query_audit.sh recent    # Ver últimas entradas"
echo "  .local/audit/query_audit.sh stats     # Ver estadísticas"
echo "  .local/audit/query_audit.sh hitl      # Ver checkpoints HITL"
echo ""
echo -e "${GREEN}🎉 ¡Listo!${NC}"
