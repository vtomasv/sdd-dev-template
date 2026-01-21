# Quick Start Guide

Guía rápida de 5 minutos para comenzar a usar el SDD Development Template con agentes de IA.

## Requisitos Previos

### Software Necesario

- **Docker** (versión 20.10+)
- **Docker Compose** (versión 2.0+)
- **Git** (versión 2.30+)
- **Editor de código** (VS Code recomendado con cc-wf-studio extension)

### API Keys Requeridas

Al menos una de las siguientes:

- **Anthropic API Key** (Claude) - **Recomendado** - [Obtener aquí](https://console.anthropic.com/)
- **Google Gemini API Key** (opcional) - [Obtener aquí](https://makersuite.google.com/app/apikey)
- **OpenAI API Key** (opcional) - [Obtener aquí](https://platform.openai.com/)
- **Ollama** (local) - Sin API key requerida

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
# Claude (recomendado)
ANTHROPIC_API_KEY=sk-ant-tu-key-aqui

# Gemini (opcional)
GEMINI_API_KEY=tu-key-aqui

# OpenAI (opcional)
OPENAI_API_KEY=sk-tu-key-aqui

# Ollama (local - sin API key)
OLLAMA_BASE_URL=http://ollama:11434

# PostgreSQL
POSTGRES_PASSWORD=sdd_secure_password_2024

# Redis
REDIS_PASSWORD=redis_secure_password_2024
```

### 3. Inicializar Proyecto

**Para proyecto Greenfield (desde cero):**

```bash
./scripts/01_init-greenfield.sh
```

**Para proyecto Brownfield (repo existente):**

```bash
./scripts/02_init-brownfield.sh https://github.com/user/repo.git /path/to/context.md
```

### 4. Levantar Stack

```bash
# Build de la imagen dev (primera vez o después de cambios)
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
sdd-ollama      Up (healthy)    11434
sdd-dev         Up              -
sdd-adminer     Up              8080
```

### 5. Verificar Instalación

```bash
# Entrar al contenedor dev
docker compose exec dev bash

# Verificar herramientas instaladas
specify --version
# Esperado: specify 0.0.90

opencode --version
# Esperado: opencode X.X.X

claude --version
# Esperado: claude X.X.X

gemini --version
# Esperado: gemini X.X.X

# Verificar todas las herramientas con Specify
specify check
```

**Salida esperada de `specify check`:**

```
✅ git: installed
✅ claude: installed
✅ gemini: installed
✅ opencode: installed
```

## Uso Básico

### Opción 1: Desarrollo Greenfield con Specify

```bash
# Dentro del contenedor dev
cd /workspace

# Inicializar proyecto con Specify
specify init . --ai claude

# Seguir el workflow de Spec-Driven Development
# 1. Crear constitución del proyecto
/speckit.constitution

# 2. Definir especificación
/speckit.specify

# 3. Crear plan técnico
/speckit.plan

# 4. Generar tareas
/speckit.tasks

# 5. Implementar
/speckit.implement
```

### Opción 2: Desarrollo con OpenCode

```bash
# Dentro del contenedor dev
cd /workspace

# Iniciar OpenCode
opencode

# Usar comandos naturales
> "Crea una API REST con FastAPI para gestión de tareas"
> "Agrega tests unitarios con pytest"
> "Documenta el código con docstrings"
```

### Opción 3: Desarrollo con Claude Code

```bash
# Dentro del contenedor dev
cd /workspace

# Iniciar Claude Code
claude

# Usar comandos naturales
> "Analiza este código y sugiere mejoras"
> "Refactoriza esta función para mejor legibilidad"
> "Genera documentación completa"
```

### Opción 4: Desarrollo con Ollama (Local)

```bash
# Configurar Ollama
./scripts/05_setup-ollama.sh

# Usar modelo local
ollama run llama3.2

# O usar el cliente Python
python3 << 'PYTHON'
from src.utils.ollama_client import get_llm_router

router = get_llm_router()
response = router.generate("Explica qué es Spec-Driven Development")
print(response)
PYTHON
```

## Workflows Visuales con cc-wf-studio

### 1. Instalar Extension en VS Code

```bash
# La extensión se sugiere automáticamente al abrir el proyecto
# O instalar manualmente desde VS Code Marketplace
```

### 2. Abrir Workflow de Ejemplo

```bash
# Desde VS Code
code .claude/workflows/spec-generation.json
```

### 3. Editar Workflow Visualmente

- Drag & drop de nodos
- Configurar SubAgents
- Agregar conditional branching
- Exportar a `.claude` format

## Sistema HITL (Human-in-the-Loop)

### Ver Checkpoints Pendientes

```bash
docker compose exec dev python src/skills/hitl_checkpoint.py list
```

### Aprobar Checkpoint

```bash
docker compose exec dev python src/skills/hitl_checkpoint.py approve <checkpoint_id>
```

### Rechazar Checkpoint

```bash
docker compose exec dev python src/skills/hitl_checkpoint.py reject <checkpoint_id> --reason "Motivo del rechazo"
```

## Sistema de Auditoría

### Ver Logs Recientes

```bash
docker compose exec dev python src/audit/logger.py --show-recent
```

### Consultar en PostgreSQL

```bash
docker compose exec postgres psql -U sdd -d sdd_db

# Ver últimas decisiones
SELECT * FROM audit_log ORDER BY timestamp DESC LIMIT 10;

# Ver checkpoints pendientes
SELECT * FROM hitl_checkpoints WHERE status = 'pending';
```

## Comandos Útiles

### Gestión de Servicios

```bash
# Ver logs en tiempo real
docker compose logs -f dev

# Reiniciar servicio específico
docker compose restart dev

# Parar todos los servicios
docker compose down

# Parar y eliminar volúmenes (⚠️ borra datos)
docker compose down -v
```

### Debugging

```bash
# Ver logs de PostgreSQL
docker compose logs postgres

# Ver logs de Ollama
docker compose logs ollama

# Acceder a Adminer (UI de PostgreSQL)
# Abrir en navegador: http://localhost:8080
# Server: postgres
# Username: sdd
# Password: (ver .env)
# Database: sdd_db
```

### Desarrollo

```bash
# Ejecutar tests
docker compose exec dev pytest

# Formatear código
docker compose exec dev black src/

# Linter
docker compose exec dev flake8 src/

# Type checking
docker compose exec dev mypy src/
```

## Troubleshooting

### "specify: command not found"

```bash
# Entrar al contenedor
docker compose exec dev bash

# Reinstalar Specify
uv tool install git+https://github.com/github/spec-kit.git

# Verificar
specify --version
```

### "uv: command not found"

```bash
# Reinstalar uv como root
docker compose exec -u root dev bash
curl -LsSf https://astral.sh/uv/install.sh | sh
mv /root/.local/bin/uv /usr/local/bin/uv
chmod +x /usr/local/bin/uv
```

### Servicios no inician

```bash
# Verificar logs
docker compose logs

# Rebuild completo
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Problemas con Ollama

```bash
# Verificar que Ollama está corriendo
docker compose ps ollama

# Ver logs
docker compose logs ollama

# Reinstalar modelos
docker compose exec ollama ollama pull llama3.2
```

## Próximos Pasos

1. **Leer documentación completa**: [README.md](../README.md)
2. **Aprender sobre HITL**: [HITL-GUIDE.md](HITL-GUIDE.md)
3. **Explorar workflows visuales**: [CC-WF-STUDIO-GUIDE.md](CC-WF-STUDIO-GUIDE.md)
4. **Configurar Ollama**: [OLLAMA-GUIDE.md](OLLAMA-GUIDE.md)
5. **Mejores prácticas**: [BEST-PRACTICES.md](BEST-PRACTICES.md)

## Recursos Adicionales

- [Spec Kit Documentation](https://github.com/github/spec-kit)
- [cc-wf-studio GitHub](https://github.com/breaking-brake/cc-wf-studio)
- [Ollama Models](https://ollama.ai/library)
- [Humanlayer Best Practices](https://www.humanlayer.dev/)
- [12-Factor Agents](https://github.com/humanlayer/12-factor-agents)

---

**¿Problemas?** Abre un [issue](https://github.com/vtomasv/sdd-dev-template/issues)
