# SDD Development Template

Template completo para desarrollo con **agentes de IA** (Claude, Gemini, OpenAI, Ollama) que soporta proyectos **Greenfield** y **Brownfield** con **HITL** (Human-in-the-Loop) y auditoría completa de decisiones de IA.

## 🚀 Características

- ✅ **Stack SDD completo** con Docker Compose (PostgreSQL + pgvector, Redis, Ollama, Dev Container)
- ✅ **Specify CLI** instalado desde GitHub para Spec-Driven Development
- ✅ **Agentes Claude** pre-configurados para Spec, Plan, Dev y Review
- ✅ **Visual Workflows** con [cc-wf-studio](https://github.com/breaking-brake/cc-wf-studio) para diseñar workflows con drag-and-drop
- ✅ **LLM Local** con Ollama para privacidad total y cero costos de API
- ✅ **Agent Skills** para generación de código, análisis de specs y recuperación de contexto
- ✅ **HITL Checkpoints** para aprobación manual en puntos críticos
- ✅ **Sistema de Auditoría** completo con logging de decisiones de IA
- ✅ **Workflows listos** para Greenfield y Brownfield (4 ejemplos incluidos)
- ✅ **MCP Integration** para herramientas externas (GitHub, Slack, etc.)
- ✅ **Múltiples proveedores de IA**: Claude (Anthropic), Gemini (Google), OpenAI, Ollama (local)
- ✅ **Mejores prácticas** de [Humanlayer](https://www.humanlayer.dev/), [12-Factor Agents](https://github.com/humanlayer/12-factor-agents) y [ACE-FCA](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md)

## 📋 Requisitos Previos

- Docker y Docker Compose instalados
- Git configurado
- API Keys (al menos una):
  - **Anthropic** (Claude) - Recomendado
  - **Google Gemini** - Opcional
  - **OpenAI** - Opcional
  - **Ollama** - Sin API key (local)

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

# 4. Levantar stack completo
docker compose up -d

# 5. Entrar al contenedor dev
docker compose exec dev bash

# 6. Verificar herramientas instaladas
specify --version
opencode --version
claude --version
gemini --version

# 7. Inicializar proyecto con Specify
specify init . --ai claude

# 8. Comenzar desarrollo
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

# 3. Inicializar proyecto brownfield con contexto
./scripts/02_init-brownfield.sh https://github.com/tu-usuario/tu-repo.git /path/to/context.md

# 4. Levantar stack completo
docker compose up -d

# 5. Entrar al contenedor dev
docker compose exec dev bash

# 6. Continuar desarrollo con contexto cargado
specify init . --ai claude
opencode
```

## 📚 Documentación

### Guías Principales
- [**QUICKSTART.md**](docs/QUICKSTART.md) - Primeros pasos detallados (5 minutos)
- [**HITL-GUIDE.md**](docs/HITL-GUIDE.md) - Cómo usar checkpoints de aprobación manual
- [**BEST-PRACTICES.md**](docs/BEST-PRACTICES.md) - 12 principios de desarrollo con agentes

### Herramientas Específicas
- [**CC-WF-STUDIO-GUIDE.md**](docs/CC-WF-STUDIO-GUIDE.md) - Diseñar workflows con drag-and-drop
- [**OLLAMA-GUIDE.md**](docs/OLLAMA-GUIDE.md) - Usar modelos locales con Ollama
- [**VALIDATION.md**](VALIDATION.md) - Checklist de validación del template

### Scripts Disponibles
- `scripts/01_init-greenfield.sh` - Inicializar proyecto desde cero
- `scripts/02_init-brownfield.sh` - Inicializar proyecto existente
- `scripts/04_audit-init.sh` - Configurar sistema de auditoría
- `scripts/05_setup-ollama.sh` - Configurar Ollama con modelos recomendados

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│          IDEs con soporte de IA                          │
│  Claude Code | OpenCode | Gemini CLI | cc-wf-studio     │
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
│                            │                             │
│  Ollama (Local LLM)        │    Adminer (DB UI)          │
│  (Privacidad total)        │    (localhost:8080)         │
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

### Workflows Visuales (cc-wf-studio)

4 workflows de ejemplo incluidos en `.claude/workflows/`:
1. **spec-generation.json** - Generación de especificaciones con HITL
2. **code-review.json** - Revisión automática de código con quality gate
3. **mcp-integration.json** - Integración con GitHub y Slack vía MCP
4. **local-llm-workflow.json** - Procesamiento privado con Ollama

## 🛠️ Comandos Útiles

### Gestión de Servicios

```bash
# Ver logs de servicios
docker compose logs -f postgres redis ollama dev

# Verificar estado de servicios
docker compose ps

# Reiniciar servicios
docker compose restart

# Rebuild del dev container (después de cambios)
docker compose build dev --no-cache
docker compose up -d
```

### Herramientas de Desarrollo

```bash
# Verificar instalación de herramientas
docker compose exec dev bash -c "specify check"

# Inicializar proyecto con Specify
docker compose exec dev bash -c "specify init . --ai claude"

# Usar Ollama localmente
docker compose exec dev bash -c "ollama list"
docker compose exec dev bash -c "ollama run llama3.2"

# Abrir cc-wf-studio (desde VSCode)
code .claude/workflows/spec-generation.json
```

### Sistema HITL

```bash
# Ver checkpoints pendientes
docker compose exec dev python src/skills/hitl_checkpoint.py list

# Aprobar checkpoint
docker compose exec dev python src/skills/hitl_checkpoint.py approve <checkpoint_id>

# Rechazar checkpoint
docker compose exec dev python src/skills/hitl_checkpoint.py reject <checkpoint_id>
```

### Sistema de Auditoría

```bash
# Ver logs de auditoría recientes
docker compose exec dev python src/audit/logger.py --show-recent

# Analizar contexto de repo brownfield
docker compose exec dev python scripts/utils/context-analyzer.py /path/to/repo

# Consultar auditoría en PostgreSQL
docker compose exec postgres psql -U sdd -d sdd_db -c "SELECT * FROM audit_log ORDER BY timestamp DESC LIMIT 10;"
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

-- Ver decisiones con contexto
SELECT agent_name, decision, context, confidence 
FROM audit_log 
WHERE confidence < 0.8 
ORDER BY timestamp DESC;
```

## 🔧 Herramientas Incluidas

### CLIs de IA
- **Specify CLI** (v0.0.90) - Spec-Driven Development
- **Claude Code** - Anthropic CLI
- **Gemini CLI** - Google CLI
- **OpenCode** - OpenAI CLI

### Workflows Visuales
- **cc-wf-studio** - Editor drag-and-drop de workflows

### LLM Local
- **Ollama** - 15 modelos recomendados (llama3.2, codellama, mistral, etc.)

### Base de Datos
- **PostgreSQL 16** con pgvector
- **Redis 7** para cache
- **Adminer** para gestión visual

## 🤝 Contribuir

Este template está diseñado para ser extensible. Para agregar nuevos agentes o skills:

1. Crear agente en `.claude/agents/`
2. Crear skill en `src/skills/`
3. Actualizar workflows en `.claude/workflows/`
4. Documentar en `docs/`
5. Hacer PR al repositorio

## 📝 Changelog

### v1.0.0 (2026-01-21)
- ✅ Template inicial con stack SDD completo
- ✅ Integración de cc-wf-studio para workflows visuales
- ✅ Integración de Ollama para LLM local
- ✅ Corrección de instalación de Specify CLI desde GitHub
- ✅ Remoción de referencias a Google Antigravity (no disponible)
- ✅ Fixes de compatibilidad macOS/Linux (sed, npm permisos)
- ✅ 4 workflows de ejemplo incluidos
- ✅ Sistema HITL completo
- ✅ Sistema de auditoría completo
- ✅ Documentación exhaustiva (7 guías)

## 📝 Licencia

MIT License - Ver [LICENSE](LICENSE) para más detalles.

## 🔗 Referencias

### Metodologías y Mejores Prácticas
- [Humanlayer](https://www.humanlayer.dev/) - HITL best practices
- [12-Factor Agents](https://github.com/humanlayer/12-factor-agents) - Principios de diseño de agentes
- [Advanced Context Engineering for Coding Agents](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md) - Context engineering

### Herramientas
- [Spec Kit](https://github.com/github/spec-kit) - Spec-Driven Development (63.9k ⭐)
- [cc-wf-studio](https://github.com/breaking-brake/cc-wf-studio) - Visual workflow editor (2.9k ⭐)
- [Ollama](https://ollama.ai/) - Local LLM runtime
- [Claude Code](https://www.anthropic.com/claude-code) - Anthropic CLI
- [OpenCode](https://github.com/opencode-ai/opencode) - OpenAI CLI

## 💬 Soporte

Para preguntas o problemas:
- Abre un [issue](https://github.com/vtomasv/sdd-dev-template/issues)
- Revisa la [documentación](docs/)
- Consulta el [changelog](#changelog)

## 🌟 Agradecimientos

Este template integra las mejores prácticas de:
- GitHub Spec Kit team
- Humanlayer community
- Breaking Brake (cc-wf-studio)
- Ollama team
- Anthropic, Google, OpenAI

---

**¿Listo para comenzar?** → [QUICKSTART.md](docs/QUICKSTART.md)
