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

# Validar argumentos
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Se requiere URL del repositorio${NC}"
    echo "Uso: ./scripts/02_init-brownfield.sh <repo-url> [context-file]"
    echo "Ejemplo: ./scripts/02_init-brownfield.sh https://github.com/user/repo.git /path/to/context.md"
    exit 1
fi

REPO_URL=$1
CONTEXT_FILE=${2:-""}
PROJECT_NAME=$(basename "$REPO_URL" .git)

echo -e "${BLUE}📦 Proyecto: ${PROJECT_NAME}${NC}"
echo -e "${BLUE}🔗 Repositorio: ${REPO_URL}${NC}"

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
mkdir -p .local/brownfield

# Generar session ID único
SESSION_ID="brownfield-$(date +%Y%m%d-%H%M%S)-$(uuidgen | cut -d'-' -f1)"
echo -e "${GREEN}🔑 Session ID: ${SESSION_ID}${NC}"

# Actualizar .env con session ID y repo URL
if grep -q "^SESSION_ID=" .env; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^SESSION_ID=.*/SESSION_ID=${SESSION_ID}/" .env
    else
        sed -i "s/^SESSION_ID=.*/SESSION_ID=${SESSION_ID}/" .env
    fi
else
    echo "SESSION_ID=${SESSION_ID}" >> .env
fi

if grep -q "^PROJECT_TYPE=" .env; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^PROJECT_TYPE=.*/PROJECT_TYPE=brownfield/" .env
    else
        sed -i "s/^PROJECT_TYPE=.*/PROJECT_TYPE=brownfield/" .env
    fi
else
    echo "PROJECT_TYPE=brownfield" >> .env
fi

if grep -q "^REPO_URL=" .env; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^REPO_URL=.*|REPO_URL=${REPO_URL}|" .env
    else
        sed -i "s|^REPO_URL=.*|REPO_URL=${REPO_URL}|" .env
    fi
else
    echo "REPO_URL=${REPO_URL}" >> .env
fi

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
REPO_DIR=".local/brownfield/${PROJECT_NAME}"
if [ -d "$REPO_DIR" ]; then
    echo -e "${YELLOW}⚠️  Repositorio ya existe. Actualizando...${NC}"
    cd "$REPO_DIR" && git pull && cd -
else
    git clone "$REPO_URL" "$REPO_DIR"
fi

# Analizar estructura del repositorio
echo -e "${BLUE}🔍 Analizando estructura del repositorio...${NC}"
ANALYSIS_FILE=".local/brownfield/${PROJECT_NAME}_analysis.json"

cat > "$ANALYSIS_FILE" <<EOF
{
  "session_id": "${SESSION_ID}",
  "project_name": "${PROJECT_NAME}",
  "repo_url": "${REPO_URL}",
  "analyzed_at": "$(date -Iseconds)",
  "structure": {
    "total_files": $(find "$REPO_DIR" -type f | wc -l),
    "languages": $(find "$REPO_DIR" -type f -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.go" | sed 's/.*\.//' | sort | uniq -c | jq -R -s -c 'split("\n")[:-1]'),
    "has_readme": $([ -f "$REPO_DIR/README.md" ] && echo "true" || echo "false"),
    "has_package_json": $([ -f "$REPO_DIR/package.json" ] && echo "true" || echo "false"),
    "has_requirements": $([ -f "$REPO_DIR/requirements.txt" ] && echo "true" || echo "false"),
    "has_dockerfile": $([ -f "$REPO_DIR/Dockerfile" ] && echo "true" || echo "false")
  }
}
EOF

echo -e "${GREEN}✅ Análisis guardado en: ${ANALYSIS_FILE}${NC}"

# Procesar archivo de contexto si se proporcionó
if [ -n "$CONTEXT_FILE" ] && [ -f "$CONTEXT_FILE" ]; then
    echo -e "${BLUE}📄 Procesando archivo de contexto...${NC}"
    CONTEXT_DEST=".local/brownfield/${PROJECT_NAME}_context.md"
    cp "$CONTEXT_FILE" "$CONTEXT_DEST"
    echo -e "${GREEN}✅ Contexto copiado a: ${CONTEXT_DEST}${NC}"
else
    echo -e "${YELLOW}⚠️  No se proporcionó archivo de contexto. Generando contexto básico...${NC}"
    CONTEXT_DEST=".local/brownfield/${PROJECT_NAME}_context.md"
    
    cat > "$CONTEXT_DEST" <<EOF
# ${PROJECT_NAME} - Contexto del Proyecto

## Información General
- **Repositorio**: ${REPO_URL}
- **Analizado**: $(date)
- **Session ID**: ${SESSION_ID}

## Estructura del Proyecto
\`\`\`
$(tree -L 2 -I 'node_modules|.git|__pycache__|venv' "$REPO_DIR" 2>/dev/null || find "$REPO_DIR" -maxdepth 2 -type d | head -20)
\`\`\`

## Archivos Principales
$(find "$REPO_DIR" -maxdepth 2 -type f -name "README*" -o -name "package.json" -o -name "requirements.txt" -o -name "Dockerfile" | head -10)

## README del Proyecto Original
$(if [ -f "$REPO_DIR/README.md" ]; then cat "$REPO_DIR/README.md"; else echo "No README encontrado"; fi)

## Notas
Este contexto fue generado automáticamente. Se recomienda complementar con:
1. Documentación de arquitectura
2. Decisiones de diseño
3. Dependencias críticas
4. Puntos de integración
5. Casos de uso principales

Para un mejor contexto, considera usar herramientas como:
- DeepWiki: https://deepwiki.com
- Repo-GPT: Para generar documentación automática
- Code2Prompt: Para extraer contexto estructurado
EOF
    
    echo -e "${GREEN}✅ Contexto básico generado en: ${CONTEXT_DEST}${NC}"
fi

# Inicializar estructura Specify
echo -e "${BLUE}📋 Inicializando estructura Specify...${NC}"
mkdir -p .specify
cat > .specify/speckit.plan <<EOF
# ${PROJECT_NAME} - Plan de Desarrollo (Brownfield)

## Contexto
Proyecto existente importado desde: ${REPO_URL}

## Objetivo
Continuar desarrollo de ${PROJECT_NAME} usando metodología SDD con agentes de IA.

## Análisis Inicial
- Repositorio analizado: ${REPO_DIR}
- Contexto disponible: ${CONTEXT_DEST}

## Fases
1. Análisis de código existente
2. Identificación de mejoras
3. Planificación de nuevas features
4. Implementación iterativa
5. Testing y validación
6. Deployment

## Estado
- Fase actual: Análisis de código existente
- Progreso: 0%
EOF

cat > .specify/speckit.tasks <<EOF
# ${PROJECT_NAME} - Tareas (Brownfield)

## Pendientes
- [ ] Revisar contexto del proyecto
- [ ] Analizar arquitectura existente
- [ ] Identificar deuda técnica
- [ ] Planificar próximas features

## En Progreso

## Completadas
- [x] Clonar repositorio existente
- [x] Generar análisis inicial
- [x] Configurar entorno brownfield
EOF

# Crear estructura de agentes Claude
echo -e "${BLUE}🤖 Configurando agentes Claude con contexto...${NC}"
cat > .claude/session.json <<EOF
{
  "session_id": "${SESSION_ID}",
  "project_name": "${PROJECT_NAME}",
  "project_type": "brownfield",
  "repo_url": "${REPO_URL}",
  "repo_path": "${REPO_DIR}",
  "context_file": "${CONTEXT_DEST}",
  "analysis_file": "${ANALYSIS_FILE}",
  "created_at": "$(date -Iseconds)",
  "agents": {
    "spec_agent": "enabled",
    "plan_agent": "enabled",
    "dev_agent": "enabled",
    "review_agent": "enabled"
  },
  "hitl_enabled": true,
  "audit_enabled": true,
  "context_loaded": true
}
EOF

echo -e "${GREEN}✅ Inicialización Brownfield completada!${NC}"
echo ""
echo -e "${BLUE}Próximos pasos:${NC}"
echo "1. Revisar contexto en: ${CONTEXT_DEST}"
echo "2. docker compose build dev"
echo "3. docker compose up -d"
echo "4. docker compose exec dev bash"
echo "5. python scripts/utils/context-analyzer.py ${REPO_DIR}"
echo "6. opencode"
echo ""
echo -e "${YELLOW}💡 Tip: Los agentes tendrán acceso al contexto del proyecto existente${NC}"
echo -e "${GREEN}🎉 ¡Listo para continuar el desarrollo!${NC}"
