# SDD Development Template

Template completo para desarrollo con **agentes de IA (Claude, Gemini, OpenAI, Ollama)** que soporta proyectos **Greenfield** y **Brownfield** con **HITL** (Human-in-the-Loop) y auditoría completa de decisiones de IA.

## 🚀 Características

- ✅ **Stack SDD completo** con Docker Compose (PostgreSQL + pgvector, Redis, Ollama, Dev Container)
- ✅ **Agentes Claude** pre-configurados para Spec, Plan, Dev y Review
- ✅ **Visual Workflows** con [cc-wf-studio](https://github.com/breaking-brake/cc-wf-studio) para diseñar workflows con drag-and-drop
- ✅ **LLM Local** con Ollama para privacidad total y cero costos de API
- ✅ **Agent Skills** para generación de código, análisis de specs y recuperación de contexto
- ✅ **HITL Checkpoints** para aprobación manual en puntos críticos
- ✅ **Sistema de Auditoría** completo con logging de decisiones de IA
- ✅ **Workflows listos** para Greenfield y Brownfield (4 ejemplos incluidos)
- ✅ **MCP Integration** para herramientas externas (GitHub, Slack, etc.)
- ✅ **Integración con múltiples proveedores de IA** de Google
- ✅ **Mejores prácticas** de [Humanlayer](https://www.humanlayer.dev/), [12-Factor Agents](https://github.com/humanlayer/12-factor-agents) y [ACE-FCA](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md)

## 📋 Requisitos Previos

- Docker y Docker Compose instalados
- Git configurado
- API Keys:
  - Anthropic (Claude)
  - OpenAI (opcional)
  - Google Gemini (opcional)

## 🏁 Quick Start

### Opción 1: Proyecto Greenfield (desde cero)

```bash
# 1. Clonar este template
git clone https://github.com/vtomasv/sdd-dev-template.git mi-proyecto
cd mi-proyecto

# 2. Configurar variables de entorno
cp .env.example .env
# Editar .env con tus API keys

# 3. Inicializar proyecto greenfield
./scripts/01_init-greenfield.sh

# 4. Levantar stack
docker compose up -d

# 5. Entrar al contenedor dev
docker compose exec dev bash

# 6. Comenzar desarrollo
specify init .
opencode
```

### Opción 2: Proyecto Brownfield (repo existente)

```bash
# 1. Clonar este template
git clone https://github.com/vtomasv/sdd-dev-template.git mi-proyecto
cd mi-proyecto

# 2. Configurar variables de entorno
cp .env.example .env
# Editar .env con tus API keys

# 3. Inicializar proyecto brownfield
./scripts/02_init-brownfield.sh https://github.com/tu-usuario/tu-repo.git /path/to/context.md

# 4. Levantar stack
docker compose up -d

# 5. Entrar al contenedor dev
docker compose exec dev bash

# 6. Continuar desarrollo con contexto cargado
opencode
```

## 📚 Documentación

### Guías Principales
- [**QUICKSTART.md**](docs/QUICKSTART.md) - Primeros pasos detallados
- [**HITL-GUIDE.md**](docs/HITL-GUIDE.md) - Cómo usar checkpoints de aprobación manual
- [**BEST-PRACTICES.md**](docs/BEST-PRACTICES.md) - Mejores prácticas

### Workflows Visuales
- [**CC-WF-STUDIO-GUIDE.md**](docs/CC-WF-STUDIO-GUIDE.md) - Diseñar workflows con drag-and-drop
- `.claude/workflows/` - 4 workflows de ejemplo incluidos

### LLM Local
- [**OLLAMA-GUIDE.md**](docs/OLLAMA-GUIDE.md) - Usar modelos locales con Ollama
- `scripts/05_setup-ollama.sh` - Script de configuración automática

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                    IDEs con soporte de IA (Claude Code, OpenCode, Gemini CLI)                       │
│                  (Google Cloud)                          │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  Dev Container                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │ Specify  │  │ OpenCode │  │  Claude  │             │
│  │   CLI    │  │    CLI   │  │   CLI    │             │
│  └──────────┘  └──────────┘  └──────────┘             │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │         Agent Skills & Workflows                │    │
│  │  • Spec Agent    • Plan Agent                   │    │
│  │  • Dev Agent     • Review Agent                 │    │
│  └────────────────────────────────────────────────┘    │
└────────────┬────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────┐
│  PostgreSQL + pgvector    │    Redis Cache              │
│  (Contexto + Embeddings)  │    (Sesiones)               │
└─────────────────────────────────────────────────────────┘
```

## 🔄 Workflows

### Greenfield Workflow
```
Start → Spec Agent → [HITL: Approve Spec] → Plan Agent → 
[HITL: Approve Plan] → Dev Agent → [HITL: Review Code] → 
Audit Log → End
```

### Brownfield Workflow
```
Start → Context Analyzer → [HITL: Validate Context] → 
Spec Agent (con contexto) → [HITL: Approve Spec] → 
Plan Agent → [HITL: Approve Plan] → Dev Agent → 
[HITL: Review Code] → Audit Log → End
```

## 🛠️ Comandos Útiles

```bash
# Ver logs de servicios
docker compose logs -f postgres redis dev

# Verificar estado de servicios
docker compose ps

# Reiniciar servicios
docker compose restart

# Ver logs de auditoría
docker compose exec dev python src/audit/logger.py --show-recent

# Ejecutar checkpoint HITL
docker compose exec dev python src/skills/hitl_checkpoint.py --checkpoint "spec-approval"

# Analizar contexto de repo brownfield
docker compose exec dev python scripts/utils/context-analyzer.py /path/to/repo
```

## 📊 Sistema de Auditoría

Todas las decisiones de IA son registradas en PostgreSQL:

```sql
-- Ver últimas decisiones
SELECT * FROM audit_log ORDER BY timestamp DESC LIMIT 10;

-- Ver decisiones por agente
SELECT agent_name, COUNT(*) FROM audit_log GROUP BY agent_name;

-- Ver checkpoints HITL
SELECT * FROM hitl_checkpoints WHERE status = 'pending';
```

## 🤝 Contribuir

Este template está diseñado para ser extensible. Para agregar nuevos agentes o skills:

1. Crear agente en `.claude/agents/`
2. Crear skill en `src/skills/`
3. Actualizar workflows en `.claude/workflows/`
4. Documentar en `docs/`

## 📝 Licencia

MIT License - Ver [LICENSE](LICENSE) para más detalles.

## 🔗 Referencias

- [Humanlayer](https://www.humanlayer.dev/)
- [12-Factor Agents](https://github.com/humanlayer/12-factor-agents)
- [Advanced Context Engineering for Coding Agents](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md)
- [Spec Kit](https://github.com/github/spec-kit)
- [OpenCode](https://github.com/opencode-ai/opencode)
- [Claude Code](https://www.anthropic.com/claude-code)

## 💬 Soporte

Para preguntas o problemas, abre un [issue](https://github.com/vtomasv/sdd-dev-template/issues).
