# Validación del Template SDD

Este documento describe cómo validar que el template está correctamente configurado.

## Checklist de Validación

### 1. Estructura de Archivos ✅

```bash
# Verificar que todos los directorios existen
test -d .claude/agents && echo "✅ .claude/agents" || echo "❌ .claude/agents"
test -d .specify && echo "✅ .specify" || echo "❌ .specify"
test -d scripts && echo "✅ scripts" || echo "❌ scripts"
test -d src/skills && echo "✅ src/skills" || echo "❌ src/skills"
test -d src/audit && echo "✅ src/audit" || echo "❌ src/audit"
test -d docs && echo "✅ docs" || echo "❌ docs"
```

### 2. Archivos Críticos ✅

```bash
# Verificar archivos principales
test -f docker-compose.yml && echo "✅ docker-compose.yml" || echo "❌ docker-compose.yml"
test -f .env.example && echo "✅ .env.example" || echo "❌ .env.example"
test -f README.md && echo "✅ README.md" || echo "❌ README.md"
test -f LICENSE && echo "✅ LICENSE" || echo "❌ LICENSE"
```

### 3. Scripts Ejecutables ✅

```bash
# Verificar permisos de ejecución
test -x scripts/01_init-greenfield.sh && echo "✅ 01_init-greenfield.sh" || echo "❌ 01_init-greenfield.sh"
test -x scripts/02_init-brownfield.sh && echo "✅ 02_init-brownfield.sh" || echo "❌ 02_init-brownfield.sh"
test -x scripts/03_setup-antigravity.sh && echo "✅ 03_setup-antigravity.sh" || echo "❌ 03_setup-antigravity.sh"
test -x scripts/04_audit-init.sh && echo "✅ 04_audit-init.sh" || echo "❌ 04_audit-init.sh"
```

### 4. Docker Compose ✅

```bash
# Validar sintaxis de docker-compose.yml
docker compose config > /dev/null && echo "✅ docker-compose.yml válido" || echo "❌ docker-compose.yml inválido"

# Build de imagen dev
docker compose build dev && echo "✅ Build exitoso" || echo "❌ Build falló"

# Levantar servicios
docker compose up -d && echo "✅ Servicios levantados" || echo "❌ Error levantando servicios"

# Verificar servicios healthy
docker compose ps | grep healthy && echo "✅ Servicios healthy" || echo "❌ Servicios no healthy"
```

### 5. Base de Datos ✅

```bash
# Verificar PostgreSQL
docker compose exec postgres psql -U sdd -d sdd -c "SELECT version();" && echo "✅ PostgreSQL funciona" || echo "❌ PostgreSQL no funciona"

# Verificar pgvector
docker compose exec postgres psql -U sdd -d sdd -c "SELECT extname FROM pg_extension WHERE extname='vector';" && echo "✅ pgvector instalado" || echo "❌ pgvector no instalado"

# Verificar tablas de auditoría
docker compose exec postgres psql -U sdd -d sdd -c "\dt" | grep audit_log && echo "✅ Tablas de auditoría" || echo "❌ Tablas de auditoría faltan"
```

### 6. Dev Container ✅

```bash
# Verificar herramientas instaladas
docker compose exec dev bash -c "specify --version" && echo "✅ Specify CLI" || echo "⚠️  Specify CLI (opcional)"
docker compose exec dev bash -c "opencode --version" && echo "✅ OpenCode CLI" || echo "❌ OpenCode CLI"
docker compose exec dev bash -c "claude --version" && echo "✅ Claude CLI" || echo "❌ Claude CLI"
docker compose exec dev bash -c "gemini --version" && echo "✅ Gemini CLI" || echo "⚠️  Gemini CLI (opcional)"
docker compose exec dev bash -c "python3 --version" && echo "✅ Python 3" || echo "❌ Python 3"
```

### 7. Python Skills ✅

```bash
# Verificar imports de Python
docker compose exec dev python3 -c "from src.skills.hitl_checkpoint import HITLCheckpointSkill; print('✅ HITL Skill')" || echo "❌ HITL Skill"
docker compose exec dev python3 -c "from src.audit.logger import get_audit_logger; print('✅ Audit Logger')" || echo "❌ Audit Logger"
```

### 8. Sistema de Auditoría ✅

```bash
# Inicializar sistema de auditoría
docker compose exec dev bash scripts/04_audit-init.sh && echo "✅ Auditoría inicializada" || echo "❌ Error en auditoría"

# Verificar entrada de prueba
docker compose exec postgres psql -U sdd -d sdd -c "SELECT COUNT(*) FROM audit_log;" && echo "✅ Audit log funciona" || echo "❌ Audit log no funciona"
```

### 9. HITL Checkpoints ✅

```bash
# Crear checkpoint de prueba
docker compose exec dev python3 -c "
from src.skills.hitl_checkpoint import HITLCheckpointSkill, CheckpointPriority
skill = HITLCheckpointSkill()
checkpoint_id = skill.create_checkpoint(
    checkpoint_name='test-checkpoint',
    agent_name='test_agent',
    data={'test': True},
    priority=CheckpointPriority.LOW
)
print(f'✅ Checkpoint creado: {checkpoint_id}')
" || echo "❌ Error creando checkpoint"

# Listar checkpoints
docker compose exec dev python3 src/skills/hitl_checkpoint.py list && echo "✅ Listar checkpoints funciona" || echo "❌ Error listando checkpoints"
```

### 10. Documentación ✅

```bash
# Verificar documentación completa
test -f docs/QUICKSTART.md && echo "✅ QUICKSTART.md" || echo "❌ QUICKSTART.md"
test -f docs/HITL-GUIDE.md && echo "✅ HITL-GUIDE.md" || echo "❌ HITL-GUIDE.md"
test -f docs/BEST-PRACTICES.md && echo "✅ BEST-PRACTICES.md" || echo "❌ BEST-PRACTICES.md"
```

## Pruebas de Integración

### Prueba 1: Proyecto Greenfield

```bash
# 1. Crear proyecto de prueba
mkdir /tmp/test-greenfield
cd /tmp/test-greenfield
git clone https://github.com/vtomasv/sdd-dev-template.git .

# 2. Configurar
cp .env.example .env
# Editar .env con API keys de prueba

# 3. Inicializar
./scripts/01_init-greenfield.sh test-project

# 4. Levantar stack
docker compose up -d

# 5. Verificar
docker compose ps
docker compose exec dev bash -c "ls -la .specify/"

# Resultado esperado:
# ✅ Proyecto inicializado
# ✅ Stack corriendo
# ✅ Estructura Specify creada
```

### Prueba 2: Proyecto Brownfield

```bash
# 1. Crear proyecto de prueba
mkdir /tmp/test-brownfield
cd /tmp/test-brownfield
git clone https://github.com/vtomasv/sdd-dev-template.git .

# 2. Configurar
cp .env.example .env
# Editar .env con API keys de prueba

# 3. Crear repo de prueba
mkdir /tmp/existing-repo
cd /tmp/existing-repo
git init
echo "# Existing Project" > README.md
git add . && git commit -m "Initial commit"

# 4. Inicializar brownfield
cd /tmp/test-brownfield
./scripts/02_init-brownfield.sh /tmp/existing-repo

# 5. Verificar
ls -la .local/brownfield/

# Resultado esperado:
# ✅ Repo clonado
# ✅ Análisis generado
# ✅ Contexto creado
```

### Prueba 3: Workflow Completo

```bash
# 1. Entrar al contenedor dev
docker compose exec dev bash

# 2. Crear especificación de prueba
cat > .specify/specs/test-api.md <<'EOF'
# API de Prueba

## Objetivo
Crear API REST simple para testing.

## Requisitos
- GET /health - Health check
- GET /version - Versión de la API
EOF

# 3. Crear checkpoint HITL
python3 -c "
from src.skills.hitl_checkpoint import HITLCheckpointSkill, CheckpointPriority
skill = HITLCheckpointSkill()
checkpoint_id = skill.create_checkpoint(
    checkpoint_name='spec-approval-test',
    agent_name='spec_agent',
    data={'spec_file': '.specify/specs/test-api.md'},
    priority=CheckpointPriority.HIGH
)
print(f'Checkpoint creado: {checkpoint_id}')
"

# 4. Listar y aprobar checkpoint
python3 src/skills/hitl_checkpoint.py list
python3 src/skills/hitl_checkpoint.py approve 1 test-user

# 5. Verificar auditoría
python3 src/audit/logger.py recent

# Resultado esperado:
# ✅ Especificación creada
# ✅ Checkpoint creado
# ✅ Checkpoint aprobado
# ✅ Auditoría registrada
```

## Script de Validación Automática

```bash
#!/bin/bash
# scripts/validate-template.sh

set -e

echo "🔍 Validando SDD Template..."
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASSED=0
FAILED=0

check() {
    if eval "$1" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $2${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ $2${NC}"
        ((FAILED++))
    fi
}

echo "📁 Estructura de archivos..."
check "test -d .claude/agents" ".claude/agents"
check "test -d scripts" "scripts"
check "test -d src/skills" "src/skills"
check "test -d docs" "docs"
echo ""

echo "📄 Archivos críticos..."
check "test -f docker-compose.yml" "docker-compose.yml"
check "test -f README.md" "README.md"
check "test -f LICENSE" "LICENSE"
echo ""

echo "🐳 Docker..."
check "docker compose config" "docker-compose.yml válido"
echo ""

echo "📊 Resumen:"
echo -e "${GREEN}Pasados: $PASSED${NC}"
echo -e "${RED}Fallados: $FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo ""
    echo "🎉 ¡Template validado correctamente!"
    exit 0
else
    echo ""
    echo "⚠️  Hay errores que corregir"
    exit 1
fi
```

## Resultados Esperados

### ✅ Template Válido

```
🔍 Validando SDD Template...

📁 Estructura de archivos...
✅ .claude/agents
✅ scripts
✅ src/skills
✅ docs

📄 Archivos críticos...
✅ docker-compose.yml
✅ README.md
✅ LICENSE

🐳 Docker...
✅ docker-compose.yml válido

📊 Resumen:
Pasados: 7
Fallados: 0

🎉 ¡Template validado correctamente!
```

## Troubleshooting

### Error: PostgreSQL no inicia

```bash
# Ver logs
docker compose logs postgres

# Limpiar volúmenes
docker compose down -v
docker compose up -d postgres
```

### Error: Dev container no puede instalar paquetes

```bash
# Rebuild sin cache
docker compose build --no-cache dev
docker compose up -d dev
```

### Error: HITL checkpoints no se crean

```bash
# Verificar HITL_ENABLED
docker compose exec dev env | grep HITL_ENABLED

# Verificar conexión a BD
docker compose exec dev python3 -c "import os; import psycopg; psycopg.connect(os.getenv('DATABASE_URL'))"
```

## Contacto

Si encuentras problemas durante la validación:
- Abre un issue: https://github.com/vtomasv/sdd-dev-template/issues
- Consulta la documentación: docs/
