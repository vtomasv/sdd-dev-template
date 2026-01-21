# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [1.1.0] - 2026-01-21

### Añadido
- Integración completa con **Specify CLI** desde GitHub
- Soporte para **OpenCode** con comandos `/speckit.*`
- Integración con **cc-wf-studio** para edición visual de workflows
- Soporte para **Ollama** (modelos locales sin API key)
- 4 workflows de ejemplo en `.claude/workflows/`
- Cliente Python para Ollama con fallback automático
- Script `05_setup-ollama.sh` para configuración de modelos locales
- Guías completas: CC-WF-STUDIO-GUIDE.md, OLLAMA-GUIDE.md
- Configuración de VSCode para extensiones recomendadas

### Cambiado
- Scripts de inicialización ahora ejecutan `specify init . --ai opencode --force` automáticamente
- Dockerfile reorganizado para instalar paquetes npm como root
- Instalación de uv mejorada con `mv` en lugar de `ln -s`
- QUICKSTART.md completamente reescrito con troubleshooting
- README.md actualizado con todas las nuevas características

### Corregido
- Error de `sed` en macOS (BSD sed vs GNU sed)
- Error de permisos npm al instalar paquetes globales
- Error "globalspecify.read_file unavailable" en OpenCode
- Instalación de Specify CLI desde GitHub (no PyPI)

### Eliminado
- Referencias a Google Antigravity (servicio no disponible públicamente)
- Variables `GOOGLE_ANTIGRAVITY_API_KEY` y `GOOGLE_ANTIGRAVITY_PROJECT_ID`
- Script `03_setup-antigravity.sh`
- Cliente `antigravity_client.py`

## [1.0.0] - 2026-01-20

### Añadido
- Template inicial para desarrollo con agentes de IA
- Docker Compose con PostgreSQL 16 + pgvector, Redis 7, Ollama
- Dev container con Python 3.12, Node.js 22
- 4 agentes Claude documentados (Spec, Plan, Dev, Review)
- Sistema HITL (Human-in-the-Loop) con checkpoints
- Sistema de auditoría completo
- Scripts de inicialización para Greenfield y Brownfield
- Documentación completa (README, QUICKSTART, HITL-GUIDE, BEST-PRACTICES)
- Estructura `.claude/` y `.specify/` lista para usar
- Soporte para Claude Code, Gemini CLI, OpenCode
- Integración con 12-Factor Agents y Humanlayer best practices

### Características del Stack
- **Base de datos**: PostgreSQL 16 con pgvector para embeddings
- **Cache**: Redis 7 para sesiones y cache
- **LLM Local**: Ollama con soporte para múltiples modelos
- **Dev Container**: Entorno completo con todas las herramientas

### Herramientas Incluidas
- Specify CLI (desde GitHub)
- Claude Code CLI
- Gemini CLI
- OpenCode CLI
- Ollama CLI
- uv (Python tooling)

### Documentación
- README.md - Vista general y quick start
- QUICKSTART.md - Guía de 5 minutos
- HITL-GUIDE.md - Human-in-the-Loop
- BEST-PRACTICES.md - 12 principios de desarrollo
- CC-WF-STUDIO-GUIDE.md - Editor visual de workflows
- OLLAMA-GUIDE.md - Modelos locales
- VALIDATION.md - Checklist de validación

---

## Próximas Versiones (Roadmap)

### [1.2.0] - Planeado
- [ ] Integración con MCP (Model Context Protocol)
- [ ] Soporte para más agentes de IA (Cursor, Windsurf)
- [ ] Dashboard web para monitoreo de agentes
- [ ] Métricas y analytics de desarrollo

### [1.3.0] - Planeado
- [ ] Integración con GitHub Actions para CI/CD
- [ ] Soporte para Kubernetes deployment
- [ ] Multi-tenancy para equipos
- [ ] API REST para gestión de proyectos

---

## Contribuir

Ver [CONTRIBUTING.md](CONTRIBUTING.md) para guías de contribución.

## Licencia

Este proyecto está licenciado bajo MIT - ver [LICENSE](LICENSE) para detalles.
