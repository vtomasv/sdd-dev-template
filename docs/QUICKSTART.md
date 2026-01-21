# 🚀 Guía de Inicio Rápido

Esta guía te llevará de cero a desarrollando con agentes de IA en 5 minutos.

## Requisitos Previos

- **Docker** y **Docker Compose** instalados
- **Git** instalado
- Al menos una API key de IA:
  - [OpenAI API Key](https://platform.openai.com/api-keys) (para OpenCode)
  - [Anthropic API Key](https://console.anthropic.com/) (para Claude)
  - [Gemini API Key](https://makersuite.google.com/app/apikey) (para Gemini)
  - O usar **Ollama** para modelos locales (sin API key)

## Paso 1: Clonar el Template

```bash
git clone https://github.com/vtomasv/sdd-dev-template.git mi-proyecto
cd mi-proyecto
```

## Paso 2: Configurar Variables de Entorno

```bash
cp .env.example .env
```

Edita `.env` y agrega tus API keys:

```bash
# Mínimo necesario (elige al menos uno)
OPENAI_API_KEY=sk-...           # Para OpenCode
ANTHROPIC_API_KEY=sk-ant-...    # Para Claude
GEMINI_API_KEY=AI...            # Para Gemini

# Ollama no requiere API key (modelos locales)
```

## Paso 3: Inicializar Proyecto

### Proyecto Greenfield (desde cero)

```bash
./scripts/01_init-greenfield.sh mi-proyecto
```

### Proyecto Brownfield (código existente)

```bash
./scripts/02_init-brownfield.sh https://github.com/user/repo.git context.md
```

## Paso 4: Levantar el Stack

```bash
# Construir contenedor de desarrollo
docker compose build dev

# Levantar todos los servicios
docker compose up -d

# Verificar que todo está corriendo
docker compose ps
```

Deberías ver:
- ✅ `postgres` - Base de datos
- ✅ `redis` - Cache
- ✅ `ollama` - LLM local
- ✅ `dev` - Contenedor de desarrollo

## Paso 5: Entrar al Contenedor de Desarrollo

```bash
docker compose exec dev bash
```

## Paso 6: Configurar Specify CLI para OpenCode

**⚠️ IMPORTANTE**: Este paso es necesario para que los comandos `/speckit.*` funcionen correctamente.

```bash
# Dentro del contenedor dev
specify init . --ai opencode --force
```

Esto configura los comandos slash de Specify para OpenCode.

## Paso 7: Verificar Herramientas

```bash
# Verificar todas las herramientas instaladas
specify check

# Verificar herramientas individuales
opencode --version
claude --version
gemini --version
ollama --version
```

## Paso 8: Comenzar Desarrollo

### Opción A: OpenCode (Recomendado)

```bash
opencode
```

Comandos slash disponibles:
- `/speckit.constitution` - Crear principios del proyecto
- `/speckit.specify` - Definir especificación
- `/speckit.plan` - Crear plan técnico
- `/speckit.tasks` - Generar lista de tareas
- `/speckit.implement` - Ejecutar implementación

### Opción B: Claude Code

```bash
claude
```

### Opción C: Gemini CLI

```bash
gemini
```

### Opción D: Ollama (Local)

```bash
# Descargar modelo
ollama pull llama3.2

# Usar con OpenCode
OPENAI_BASE_URL=http://ollama:11434/v1 opencode
```

## Flujo de Desarrollo SDD

### 1. Establecer Principios

```
/speckit.constitution Crear principios enfocados en calidad de código, 
testing, experiencia de usuario y rendimiento
```

### 2. Definir Especificación

```
/speckit.specify Construir una API REST para gestión de tareas con 
autenticación JWT, CRUD completo y filtros avanzados
```

### 3. Crear Plan Técnico

```
/speckit.plan Usar FastAPI con PostgreSQL, SQLAlchemy ORM, 
pytest para testing y Docker para deployment
```

### 4. Generar Tareas

```
/speckit.tasks
```

### 5. Implementar

```
/speckit.implement
```

## Troubleshooting

### Error: "specify: command not found"

```bash
# Dentro del contenedor
uv tool install git+https://github.com/github/spec-kit.git
```

### Error: "globalspecify.read_file unavailable"

Este error ocurre cuando Specify no está configurado para OpenCode:

```bash
# Ejecutar dentro del contenedor
specify init . --ai opencode --force
```

### Error: "opencode: command not found"

```bash
# Verificar instalación
which opencode

# Si no está, reinstalar
npm install -g opencode-ai
```

### Error: "Cannot connect to Ollama"

```bash
# Verificar que Ollama está corriendo
docker compose ps ollama

# Reiniciar si es necesario
docker compose restart ollama
```

### Error: "Docker build fails"

```bash
# Limpiar cache y reconstruir
docker compose build dev --no-cache
```

## Próximos Pasos

1. **Leer la documentación completa**:
   - [HITL-GUIDE.md](HITL-GUIDE.md) - Human-in-the-Loop
   - [OLLAMA-GUIDE.md](OLLAMA-GUIDE.md) - Modelos locales
   - [CC-WF-STUDIO-GUIDE.md](CC-WF-STUDIO-GUIDE.md) - Editor visual de workflows
   - [BEST-PRACTICES.md](BEST-PRACTICES.md) - Mejores prácticas

2. **Explorar workflows de ejemplo**:
   ```bash
   ls .claude/workflows/
   ```

3. **Configurar cc-wf-studio** en VSCode para editar workflows visualmente

4. **Probar HITL** para checkpoints de aprobación manual

## Recursos

- [GitHub Spec Kit](https://github.com/github/spec-kit) - 64k ⭐
- [OpenCode](https://opencode.ai/) - CLI de IA
- [Humanlayer](https://www.humanlayer.dev/) - HITL best practices
- [12-Factor Agents](https://github.com/humanlayer/12-factor-agents) - Principios de diseño

---

**¿Problemas?** Abre un issue en el repositorio o consulta la documentación completa.
