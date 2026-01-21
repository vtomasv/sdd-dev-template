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
SESSION_ID="greenfield-$(date +%Y%m%d-%H%M%S)-$(uuidgen | cut -d'-' -f1 2>/dev/null || echo $RANDOM)"
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

# Inicializar estructura Specify con el agente correcto
echo -e "${BLUE}📋 Inicializando Specify CLI para OpenCode...${NC}"

# Detectar qué agente de IA usar (por defecto opencode)
AI_AGENT=${AI_AGENT:-opencode}

# Verificar si specify está instalado
if command -v specify &> /dev/null; then
    echo -e "${BLUE}🔧 Ejecutando: specify init . --ai ${AI_AGENT} --force${NC}"
    specify init . --ai ${AI_AGENT} --force --no-git 2>/dev/null || {
        echo -e "${YELLOW}⚠️  specify init falló, creando estructura manual...${NC}"
        mkdir -p .specify/memory .specify/specs .specify/commands
    }
else
    echo -e "${YELLOW}⚠️  Specify CLI no encontrado. Se configurará dentro del contenedor Docker.${NC}"
    echo -e "${YELLOW}   Después de 'docker compose exec dev bash', ejecuta:${NC}"
    echo -e "${YELLOW}   specify init . --ai opencode --force${NC}"
    mkdir -p .specify/memory .specify/specs .specify/commands
fi

# Crear archivos de plan y tareas
cat > .specify/speckit.plan <<PLAN
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
PLAN

cat > .specify/speckit.tasks <<TASKS
# ${PROJECT_NAME} - Tareas

## Pendientes
- [ ] Definir especificación inicial
- [ ] Crear arquitectura base
- [ ] Configurar entorno de desarrollo

## En Progreso

## Completadas
- [x] Inicializar proyecto greenfield
TASKS

# Crear estructura de agentes Claude
echo -e "${BLUE}🤖 Configurando agentes Claude...${NC}"
mkdir -p .claude
cat > .claude/session.json <<SESSION
{
  "session_id": "${SESSION_ID}",
  "project_name": "${PROJECT_NAME}",
  "project_type": "greenfield",
  "created_at": "$(date -Iseconds)",
  "ai_agent": "${AI_AGENT}",
  "agents": {
    "spec_agent": "enabled",
    "plan_agent": "enabled",
    "dev_agent": "enabled",
    "review_agent": "enabled"
  },
  "hitl_enabled": true,
  "audit_enabled": true
}
SESSION

# Crear README del proyecto
if [ ! -f README.md ] || [ "$(wc -l < README.md)" -lt 5 ]; then
    echo -e "${BLUE}📝 Creando README del proyecto...${NC}"
    cat > README.md <<README
# ${PROJECT_NAME}

Proyecto creado usando SDD Development Template.

## Estado

- **Tipo**: Greenfield
- **Session ID**: ${SESSION_ID}
- **AI Agent**: ${AI_AGENT}
- **Creado**: $(date)

## Comenzar

\`\`\`bash
# Levantar stack
docker compose up -d

# Entrar al contenedor dev
docker compose exec dev bash

# Verificar herramientas
specify check

# Inicializar Specify (si no se hizo automáticamente)
specify init . --ai opencode --force

# Comenzar desarrollo
opencode
\`\`\`

## Comandos Slash Disponibles

Una vez dentro de OpenCode, usa estos comandos:

- \`/speckit.constitution\` - Crear principios del proyecto
- \`/speckit.specify\` - Definir especificación
- \`/speckit.plan\` - Crear plan técnico
- \`/speckit.tasks\` - Generar lista de tareas
- \`/speckit.implement\` - Ejecutar implementación

## Documentación

Ver [docs/](docs/) para guías detalladas.
README
fi

echo -e "${GREEN}✅ Inicialización Greenfield completada!${NC}"
echo ""
echo -e "${BLUE}Próximos pasos:${NC}"
echo "1. docker compose build dev"
echo "2. docker compose up -d"
echo "3. docker compose exec dev bash"
echo "4. specify init . --ai opencode --force  # Solo si no se ejecutó automáticamente"
echo "5. opencode"
echo ""
echo -e "${YELLOW}📝 IMPORTANTE: Dentro del contenedor, ejecuta 'specify init . --ai opencode --force'${NC}"
echo -e "${YELLOW}   para configurar correctamente los comandos /speckit.* para OpenCode${NC}"
echo ""
echo -e "${GREEN}🎉 ¡Listo para comenzar el desarrollo!${NC}"
