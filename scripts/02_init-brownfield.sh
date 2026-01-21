#!/bin/bash
set -e

# Script de inicialización para proyectos Brownfield
# Uso: ./scripts/02_init-brownfield.sh <repo-url> [context-file]

echo "🔄 Iniciando configuración Brownfield..."

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar argumentos
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Debes proporcionar la URL del repositorio${NC}"
    echo "Uso: ./scripts/02_init-brownfield.sh <repo-url> [context-file]"
    echo ""
    echo "Ejemplos:"
    echo "  ./scripts/02_init-brownfield.sh https://github.com/user/repo.git"
    echo "  ./scripts/02_init-brownfield.sh https://github.com/user/repo.git /path/to/context.md"
    exit 1
fi

REPO_URL=$1
CONTEXT_FILE=${2:-""}

echo -e "${BLUE}📦 Repositorio: ${REPO_URL}${NC}"
if [ -n "$CONTEXT_FILE" ]; then
    echo -e "${BLUE}📄 Archivo de contexto: ${CONTEXT_FILE}${NC}"
fi

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
mkdir -p .local/brownfield/source .local/brownfield/context

# Generar session ID único
SESSION_ID="brownfield-$(date +%Y%m%d-%H%M%S)-$(uuidgen | cut -d'-' -f1 2>/dev/null || echo $RANDOM)"
echo -e "${GREEN}🔑 Session ID: ${SESSION_ID}${NC}"

# Actualizar .env con session ID
if grep -q "^SESSION_ID=" .env; then
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
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^PROJECT_TYPE=.*/PROJECT_TYPE=brownfield/" .env
    else
        sed -i "s/^PROJECT_TYPE=.*/PROJECT_TYPE=brownfield/" .env
    fi
else
    echo "PROJECT_TYPE=brownfield" >> .env
fi

# Guardar URL del repo
if grep -q "^REPO_URL=" .env; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^REPO_URL=.*|REPO_URL=${REPO_URL}|" .env
    else
        sed -i "s|^REPO_URL=.*|REPO_URL=${REPO_URL}|" .env
    fi
else
    echo "REPO_URL=${REPO_URL}" >> .env
fi

# Guardar archivo de contexto si se proporcionó
if [ -n "$CONTEXT_FILE" ]; then
    if grep -q "^CONTEXT_FILE=" .env; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|^CONTEXT_FILE=.*|CONTEXT_FILE=${CONTEXT_FILE}|" .env
        else
            sed -i "s|^CONTEXT_FILE=.*|CONTEXT_FILE=${CONTEXT_FILE}|" .env
        fi
    else
        echo "CONTEXT_FILE=${CONTEXT_FILE}" >> .env
    fi
fi

# Clonar repositorio existente
echo -e "${BLUE}📥 Clonando repositorio existente...${NC}"
if [ -d ".local/brownfield/source/.git" ]; then
    echo -e "${YELLOW}⚠️  Repositorio ya clonado, actualizando...${NC}"
    cd .local/brownfield/source && git pull && cd ../../..
else
    git clone "$REPO_URL" .local/brownfield/source
fi

# Copiar archivo de contexto si existe
if [ -n "$CONTEXT_FILE" ] && [ -f "$CONTEXT_FILE" ]; then
    echo -e "${BLUE}📋 Copiando archivo de contexto...${NC}"
    cp "$CONTEXT_FILE" .local/brownfield/context/deepwiki-context.md
fi

# Analizar repositorio y generar contexto
echo -e "${BLUE}🔍 Analizando repositorio...${NC}"
REPO_NAME=$(basename "$REPO_URL" .git)
TOTAL_FILES=$(find .local/brownfield/source -type f | wc -l)
CODE_FILES=$(find .local/brownfield/source -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.go" -o -name "*.rs" -o -name "*.rb" \) | wc -l)

cat > .local/brownfield/context/analysis.md <<ANALYSIS
# Análisis de Repositorio Brownfield

## Información General
- **Repositorio**: ${REPO_NAME}
- **URL**: ${REPO_URL}
- **Session ID**: ${SESSION_ID}
- **Fecha de análisis**: $(date)

## Estadísticas
- **Total de archivos**: ${TOTAL_FILES}
- **Archivos de código**: ${CODE_FILES}

## Estructura de Directorios
\`\`\`
$(find .local/brownfield/source -type d -maxdepth 3 | head -30)
\`\`\`

## Archivos Principales
\`\`\`
$(find .local/brownfield/source -type f -maxdepth 2 | head -20)
\`\`\`

## Contexto Adicional
$(if [ -f ".local/brownfield/context/deepwiki-context.md" ]; then
    echo "Se proporcionó archivo de contexto adicional (deepwiki-context.md)"
else
    echo "No se proporcionó archivo de contexto adicional"
fi)
ANALYSIS

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
# ${REPO_NAME} - Plan de Desarrollo Brownfield

## Objetivo
Continuar desarrollo de ${REPO_NAME} usando metodología SDD con agentes de IA.

## Contexto
Este es un proyecto brownfield. El código existente ha sido analizado y el contexto está disponible en:
- .local/brownfield/source/ - Código fuente original
- .local/brownfield/context/analysis.md - Análisis automático
- .local/brownfield/context/deepwiki-context.md - Contexto adicional (si existe)

## Fases
1. Análisis del código existente
2. Identificación de mejoras
3. Planificación de cambios
4. Implementación iterativa
5. Testing y validación

## Estado
- Fase actual: Análisis del código existente
- Progreso: 10%
PLAN

cat > .specify/speckit.tasks <<TASKS
# ${REPO_NAME} - Tareas Brownfield

## Pendientes
- [ ] Revisar análisis del repositorio
- [ ] Leer contexto de deepwiki (si existe)
- [ ] Identificar áreas de mejora
- [ ] Definir especificación de cambios

## En Progreso
- [ ] Análisis inicial del código

## Completadas
- [x] Clonar repositorio existente
- [x] Generar análisis automático
- [x] Inicializar proyecto brownfield
TASKS

# Crear estructura de agentes Claude
echo -e "${BLUE}🤖 Configurando agentes Claude...${NC}"
mkdir -p .claude
cat > .claude/session.json <<SESSION
{
  "session_id": "${SESSION_ID}",
  "project_name": "${REPO_NAME}",
  "project_type": "brownfield",
  "repo_url": "${REPO_URL}",
  "context_file": "${CONTEXT_FILE}",
  "created_at": "$(date -Iseconds)",
  "ai_agent": "${AI_AGENT}",
  "agents": {
    "spec_agent": "enabled",
    "plan_agent": "enabled",
    "dev_agent": "enabled",
    "review_agent": "enabled"
  },
  "hitl_enabled": true,
  "audit_enabled": true,
  "brownfield": {
    "source_path": ".local/brownfield/source",
    "context_path": ".local/brownfield/context",
    "analysis_file": ".local/brownfield/context/analysis.md"
  }
}
SESSION

echo -e "${GREEN}✅ Inicialización Brownfield completada!${NC}"
echo ""
echo -e "${BLUE}📊 Resumen:${NC}"
echo "  - Repositorio clonado: .local/brownfield/source/"
echo "  - Análisis generado: .local/brownfield/context/analysis.md"
if [ -f ".local/brownfield/context/deepwiki-context.md" ]; then
    echo "  - Contexto adicional: .local/brownfield/context/deepwiki-context.md"
fi
echo ""
echo -e "${BLUE}Próximos pasos:${NC}"
echo "1. docker compose build dev"
echo "2. docker compose up -d"
echo "3. docker compose exec dev bash"
echo "4. specify init . --ai opencode --force  # Configurar comandos /speckit.*"
echo "5. opencode"
echo ""
echo -e "${YELLOW}📝 IMPORTANTE: Dentro del contenedor, ejecuta 'specify init . --ai opencode --force'${NC}"
echo -e "${YELLOW}   para configurar correctamente los comandos /speckit.* para OpenCode${NC}"
echo ""
echo -e "${GREEN}🎉 ¡Listo para continuar el desarrollo!${NC}"
