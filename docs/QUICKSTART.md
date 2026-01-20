# Quick Start Guide

Guía rápida para comenzar a usar el SDD Development Template con Antigravity de Google.

## Requisitos Previos

### Software Necesario
- **Docker** (versión 20.10+)
- **Docker Compose** (versión 2.0+)
- **Git** (versión 2.30+)
- **Editor de código** (VS Code recomendado)

### API Keys Requeridas
- **Anthropic API Key** (Claude) - [Obtener aquí](https://console.anthropic.com/)
- **Google Antigravity API Key** - [Obtener aquí](https://cloud.google.com/antigravity)
- **OpenAI API Key** (opcional) - [Obtener aquí](https://platform.openai.com/)
- **Google Gemini API Key** (opcional) - [Obtener aquí](https://ai.google.dev/)

## Instalación Rápida

### 1. Clonar el Template

```bash
# Opción A: Usar como template en GitHub
# Ve a: https://github.com/vtomasv/sdd-dev-template
# Click en "Use this template" → "Create a new repository"

# Opción B: Clonar directamente
git clone https://github.com/vtomasv/sdd-dev-template.git mi-proyecto
cd mi-proyecto
```

### 2. Configurar Variables de Entorno

```bash
# Copiar archivo de ejemplo
cp .env.example .env

# Editar con tus API keys
nano .env  # o vim, code, etc.
```

**Variables críticas a configurar:**
```bash
# Claude (requerido)
ANTHROPIC_API_KEY=sk-ant-tu-key-aqui

# Antigravity (requerido)
GOOGLE_ANTIGRAVITY_API_KEY=tu-key-aqui
GOOGLE_ANTIGRAVITY_PROJECT_ID=tu-project-id

# Opcionales
OPENAI_API_KEY=sk-tu-key-aqui
GEMINI_API_KEY=tu-key-aqui
```

### 3. Inicializar Proyecto

**Para proyecto Greenfield (desde cero):**
```bash
./scripts/01_init-greenfield.sh mi-proyecto
```

**Para proyecto Brownfield (repo existente):**
```bash
./scripts/02_init-brownfield.sh https://github.com/user/repo.git /path/to/context.md
```

### 4. Levantar Stack

```bash
# Build de la imagen dev
docker compose build dev

# Levantar todos los servicios
docker compose up -d

# Verificar que todo está corriendo
docker compose ps
```

**Salida esperada:**
```
NAME            STATUS          PORTS
sdd-postgres    Up (healthy)    5432
sdd-redis       Up (healthy)    6379
sdd-dev         Up              -
sdd-adminer     Up              8080
```

### 5. Verificar Instalación

```bash
# Entrar al contenedor dev
docker compose exec dev bash

# Verificar herramientas instaladas
specify --version
opencode --version
claude --version
gemini --version

# Verificar conexión a PostgreSQL
python - <<'PY'
import os, psycopg
with psycopg.connect(os.environ['DATABASE_URL']) as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT extname FROM pg_extension WHERE extname='vector'")
        print("✅ pgvector:", cur.fetchone())
PY
```

### 6. Inicializar Sistema de Auditoría

```bash
# Dentro del contenedor dev
./scripts/04_audit-init.sh
```

### 7. Configurar Antigravity (opcional pero recomendado)

```bash
# Dentro del contenedor dev
./scripts/03_setup-antigravity.sh

# Probar conexión
python .local/antigravity/test_connection.py
```

## Primer Proyecto

### Greenfield: Crear API REST desde Cero

```bash
# 1. Dentro del contenedor dev
docker compose exec dev bash

# 2. Inicializar Specify
specify init .

# 3. Crear especificación
cat > .specify/specs/api-rest.md <<'EOF'
# API REST de Tareas

## Objetivo
Crear una API REST simple para gestión de tareas (TODO list).

## Requisitos Funcionales
- CRUD de tareas (Create, Read, Update, Delete)
- Listar todas las tareas
- Filtrar por estado (pendiente, completada)
- Marcar tarea como completada

## Stack Técnico
- Backend: Python + FastAPI
- Database: PostgreSQL
- Testing: pytest
EOF

# 4. Iniciar OpenCode
opencode

# 5. En OpenCode, ejecutar:
# "Genera la especificación completa para la API REST de tareas"
# "Crea el plan de implementación"
# "Implementa el backend de la API"
```

### Brownfield: Continuar Proyecto Existente

```bash
# 1. Ya clonaste el repo con init-brownfield.sh

# 2. Revisar contexto generado
cat .local/brownfield/mi-proyecto_context.md

# 3. Entrar al contenedor dev
docker compose exec dev bash

# 4. Analizar código existente
python scripts/utils/context-analyzer.py .local/brownfield/mi-proyecto

# 5. Iniciar OpenCode con contexto
opencode

# 6. En OpenCode:
# "Analiza el código existente y genera un resumen"
# "Identifica áreas de mejora"
# "Propón una nueva feature basada en el contexto"
```

## Uso de HITL Checkpoints

Los checkpoints HITL permiten aprobación manual en puntos críticos:

```bash
# Listar checkpoints pendientes
python src/skills/hitl_checkpoint.py list

# Aprobar un checkpoint
python src/skills/hitl_checkpoint.py approve <checkpoint-id> <tu-nombre>

# Rechazar un checkpoint
python src/skills/hitl_checkpoint.py reject <checkpoint-id> <tu-nombre> "Razón del rechazo"
```

## Consultar Auditoría

```bash
# Ver últimas decisiones
python src/audit/logger.py recent

# Ver decisiones de un agente específico
python src/audit/logger.py by-agent spec_agent

# Ver estadísticas
python src/audit/logger.py stats

# Generar reporte
python src/audit/logger.py report
```

## Comandos Útiles

### Docker Compose

```bash
# Ver logs
docker compose logs -f dev

# Reiniciar servicios
docker compose restart

# Detener todo
docker compose down

# Detener y limpiar volúmenes
docker compose down -v
```

### Base de Datos

```bash
# Acceder a PostgreSQL
docker compose exec postgres psql -U sdd -d sdd

# Ver tablas
docker compose exec postgres psql -U sdd -d sdd -c "\dt"

# Consultar audit log
docker compose exec postgres psql -U sdd -d sdd -c "SELECT * FROM audit_log ORDER BY timestamp DESC LIMIT 10;"
```

### Adminer (UI de Base de Datos)

Abre en tu navegador: http://localhost:8080

- **Sistema**: PostgreSQL
- **Servidor**: postgres
- **Usuario**: sdd
- **Contraseña**: sdd_password
- **Base de datos**: sdd

## Estructura de Archivos

```
mi-proyecto/
├── .claude/              # Agentes y workflows de Claude
│   ├── agents/          # Definiciones de agentes
│   ├── commands/        # Comandos disponibles
│   └── workflows/       # Workflows predefinidos
├── .specify/            # Especificaciones y planes
│   ├── speckit.plan    # Plan general
│   ├── speckit.tasks   # Tareas
│   └── specs/          # Especificaciones detalladas
├── src/                 # Código fuente
│   ├── agents/         # Implementación de agentes
│   ├── skills/         # Agent skills
│   ├── audit/          # Sistema de auditoría
│   └── utils/          # Utilidades
├── scripts/             # Scripts de inicialización
├── docs/                # Documentación
└── docker-compose.yml   # Configuración de servicios
```

## Próximos Pasos

1. **Leer documentación completa**:
   - [GREENFIELD.md](GREENFIELD.md) - Guía detallada para proyectos desde cero
   - [BROWNFIELD.md](BROWNFIELD.md) - Guía detallada para proyectos existentes
   - [HITL-GUIDE.md](HITL-GUIDE.md) - Guía de checkpoints HITL
   - [AUDIT-GUIDE.md](AUDIT-GUIDE.md) - Guía de auditoría
   - [AGENT-SKILLS.md](AGENT-SKILLS.md) - Documentación de agent skills

2. **Explorar agentes**:
   - Revisar `.claude/agents/` para entender cada agente
   - Personalizar workflows en `.claude/workflows/`

3. **Configurar notificaciones**:
   - Slack webhooks para checkpoints HITL
   - Email para alertas críticas

4. **Integrar con CI/CD**:
   - GitHub Actions para testing automático
   - Deployment automático

## Solución de Problemas

### PostgreSQL no inicia

```bash
# Ver logs
docker compose logs postgres

# Limpiar volúmenes y reiniciar
docker compose down -v
docker compose up -d postgres
```

### Dev container no puede conectar a PostgreSQL

```bash
# Verificar que postgres esté healthy
docker compose ps

# Verificar variable DATABASE_URL
docker compose exec dev env | grep DATABASE_URL

# Probar conexión manual
docker compose exec dev python -c "import psycopg; psycopg.connect('postgresql://sdd:sdd_password@postgres:5432/sdd')"
```

### Herramientas CLI no encontradas

```bash
# Rebuild del contenedor dev
docker compose build --no-cache dev
docker compose up -d dev
```

## Soporte

- **Documentación**: Ver carpeta `docs/`
- **Issues**: https://github.com/vtomasv/sdd-dev-template/issues
- **Discusiones**: https://github.com/vtomasv/sdd-dev-template/discussions

## Referencias

- [Humanlayer](https://www.humanlayer.dev/)
- [12-Factor Agents](https://github.com/humanlayer/12-factor-agents)
- [ACE-FCA](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md)
- [Google Antigravity](https://cloud.google.com/antigravity)
- [Spec Kit](https://github.com/github/spec-kit)
