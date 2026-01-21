#!/bin/bash
set -e

# Script de inicialización para proyectos Greenfield
# Uso: ./scripts/01_init-greenfield.sh [project-name]

echo "🚀 Iniciando configuración Greenfield..."

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Obtener nombre del proyecto
PROJECT_NAME=${1:-$(basename $(pwd))}
echo -e "${BLUE}📦 Proyecto: ${PROJECT_NAME}${NC}"

# Verificar que .env existe
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  Archivo .env no encontrado. Copiando desde .env.example...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}⚠️  Por favor edita .env con tus API keys antes de continuar.${NC}"
    echo -e "${YELLOW}   Presiona Enter cuando hayas configurado .env...${NC}"
    read
fi

# Crear directorios locales
echo -e "${BLUE}📁 Creando directorios locales...${NC}"
mkdir -p .data/pgdata .data/redis .data/ollama
mkdir -p .local/claude .local/opencode .local/cache .local/specify .local/audit

# Generar session ID único
SESSION_ID="greenfield-$(date +%Y%m%d-%H%M%S)-$(uuidgen | cut -d'-' -f1)"
echo -e "${GREEN}🔑 Session ID: ${SESSION_ID}${NC}"

# Actualizar .env con session ID
if grep -q "^SESSION_ID=" .env; then
    # Compatibilidad macOS/Linux
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^SESSION_ID=.*/SESSION_ID=${SESSION_ID}/" .env
    else
        sed -i "s/^SESSION_ID=.*/SESSION_ID=${SESSION_ID}/" .env
    fi
else
    echo "SESSION_ID=${SESSION_ID}" >> .env
fi

# Actualizar PROJECT_TYPE
if grep -q "^PROJECT_TYPE=" .env; then
    # Compatibilidad macOS/Linux
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^PROJECT_TYPE=.*/PROJECT_TYPE=greenfield/" .env
    else
        sed -i "s/^PROJECT_TYPE=.*/PROJECT_TYPE=greenfield/" .env
    fi
else
    echo "PROJECT_TYPE=greenfield" >> .env
fi

# Inicializar estructura Specify
echo -e "${BLUE}📋 Inicializando estructura Specify...${NC}"
mkdir -p .specify
cat > .specify/speckit.plan <<EOF
# ${PROJECT_NAME} - Plan de Desarrollo

## Objetivo
Desarrollar ${PROJECT_NAME} usando metodología SDD con agentes de IA.

## Fases
1. Especificación inicial
2. Planificación de arquitectura
3. Implementación iterativa
4. Testing y validación
5. Deployment

## Estado
- Fase actual: Especificación inicial
- Progreso: 0%
EOF

cat > .specify/speckit.tasks <<EOF
# ${PROJECT_NAME} - Tareas

## Pendientes
- [ ] Definir especificación inicial
- [ ] Crear arquitectura base
- [ ] Configurar entorno de desarrollo

## En Progreso

## Completadas
- [x] Inicializar proyecto greenfield
EOF

# Crear estructura de agentes Claude
echo -e "${BLUE}🤖 Configurando agentes Claude...${NC}"
cat > .claude/session.json <<EOF
{
  "session_id": "${SESSION_ID}",
  "project_name": "${PROJECT_NAME}",
  "project_type": "greenfield",
  "created_at": "$(date -Iseconds)",
  "agents": {
    "spec_agent": "enabled",
    "plan_agent": "enabled",
    "dev_agent": "enabled",
    "review_agent": "enabled"
  },
  "hitl_enabled": true,
  "audit_enabled": true
}
EOF

# Crear README del proyecto
if [ ! -f README.md ] || [ "$(cat README.md)" == "" ]; then
    echo -e "${BLUE}📝 Creando README del proyecto...${NC}"
    cat > README.md <<EOF
# ${PROJECT_NAME}

Proyecto creado usando SDD Development Template.

## Estado
- **Tipo**: Greenfield
- **Session ID**: ${SESSION_ID}
- **Creado**: $(date)

## Comenzar

\`\`\`bash
# Levantar stack
docker compose up -d

# Entrar al contenedor dev
docker compose exec dev bash

# Inicializar Specify
specify init .

# Comenzar desarrollo con OpenCode
opencode
\`\`\`

## Documentación
Ver [docs/](docs/) para guías detalladas.
EOF
fi

echo -e "${GREEN}✅ Inicialización Greenfield completada!${NC}"
echo ""
echo -e "${BLUE}Próximos pasos:${NC}"
echo "1. docker compose build dev"
echo "2. docker compose up -d"
echo "3. docker compose exec dev bash"
echo "4. specify init ."
echo "5. opencode"
echo ""
echo -e "${GREEN}🎉 ¡Listo para comenzar el desarrollo!${NC}"
