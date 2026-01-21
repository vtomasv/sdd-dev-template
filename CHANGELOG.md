# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [1.0.0] - 2026-01-21

### Añadido

#### Infraestructura
- Stack SDD completo con Docker Compose
- PostgreSQL 16 con extensión pgvector para embeddings
- Redis 7 para cache y sesiones
- Ollama para LLM local con privacidad total
- Adminer para gestión visual de PostgreSQL
- Dev Container con todas las herramientas pre-instaladas

#### Herramientas de Desarrollo
- **Specify CLI** (v0.0.90) instalado desde GitHub para Spec-Driven Development
- **Claude Code** CLI de Anthropic
- **Gemini CLI** de Google
- **OpenCode** CLI de OpenAI
- **uv** como gestor de herramientas Python
- **cc-wf-studio** extension para workflows visuales

#### Agentes y Skills
- 4 agentes Claude pre-configurados:
  - Spec Agent - Generación de especificaciones
  - Plan Agent - Creación de planes de implementación
  - Dev Agent - Implementación de código
  - Review Agent - Revisión de código y calidad
- Agent skills para generación de código y análisis
- Sistema de recuperación de contexto con pgvector

#### HITL (Human-in-the-Loop)
- Sistema completo de checkpoints de aprobación manual
- 4 niveles de prioridad: LOW, MEDIUM, HIGH, CRITICAL
- CLI para gestión de checkpoints (list, approve, reject)
- Integración con workflows de agentes

#### Sistema de Auditoría
- Logging completo de decisiones de IA en PostgreSQL
- Trazabilidad de todas las acciones de agentes
- Métricas de confianza y contexto
- Consultas SQL para análisis de auditoría

#### Workflows
- 4 workflows de ejemplo en `.claude/workflows/`:
  1. `spec-generation.json` - Generación de specs con HITL
  2. `code-review.json` - Review automático con quality gate
  3. `mcp-integration.json` - Integración GitHub + Slack
  4. `local-llm-workflow.json` - Procesamiento privado con Ollama

#### Scripts de Inicialización
- `01_init-greenfield.sh` - Proyectos desde cero
- `02_init-brownfield.sh` - Proyectos existentes con análisis de contexto
- `04_audit-init.sh` - Configuración de sistema de auditoría
- `05_setup-ollama.sh` - Configuración interactiva de Ollama

#### Documentación
- README.md completo con arquitectura y ejemplos
- QUICKSTART.md - Guía de 5 minutos
- HITL-GUIDE.md - Guía completa de HITL
- CC-WF-STUDIO-GUIDE.md - Tutorial de workflows visuales
- OLLAMA-GUIDE.md - Guía exhaustiva de Ollama
- BEST-PRACTICES.md - 12 principios de desarrollo con agentes
- VALIDATION.md - Checklist de validación

#### Integración con Ollama
- Cliente Python completo con streaming
- Router automático (local → cloud fallback)
- 15 modelos recomendados documentados
- Configuración en docker-compose.yml
- Variables de entorno en .env.example

#### Integración con cc-wf-studio
- Configuración de VSCode (extensions.json, settings.json)
- 4 workflows de ejemplo en formato JSON
- Documentación completa de uso
- Soporte para MCP tools

### Cambiado

#### Instalación de uv
- Cambio de `ln -s` a `mv` para mejor compatibilidad
- Instalación como root antes de cambiar a usuario dev
- PATH actualizado para incluir `/home/dev/.local/bin`

#### Instalación de Specify CLI
- Cambio de `uv tool install specify-cli` (no disponible en PyPI)
- A `uv tool install git+https://github.com/github/spec-kit.git` (método oficial)

#### Scripts de Inicialización
- Compatibilidad con macOS (BSD sed) y Linux (GNU sed)
- Detección automática de sistema operativo con `$OSTYPE`

#### Dockerfile
- Instalación de paquetes npm globales como root antes de USER dev
- Orden optimizado de instalaciones para evitar errores de permisos

#### Mensajes de Bienvenida
- Actualizado de comandos específicos a lista de herramientas
- Más claro y conciso

### Removido

#### Google Antigravity
- Removidas todas las referencias a Google Antigravity (servicio no disponible públicamente)
- Removido `scripts/03_setup-antigravity.sh`
- Removido `src/utils/antigravity_client.py`
- Removido `.local/antigravity/` directorio
- Removidas variables `GOOGLE_ANTIGRAVITY_API_KEY` y `GOOGLE_ANTIGRAVITY_PROJECT_ID` de `.env.example`

### Corregido

#### Compatibilidad macOS
- Scripts de inicialización ahora funcionan en macOS y Linux
- Detección automática de BSD sed vs GNU sed
- Sintaxis correcta para ambos sistemas

#### Permisos npm
- Paquetes globales npm se instalan como root antes de cambiar a usuario dev
- Evita errores EACCES en `/usr/lib/node_modules/`

#### Instalación de uv
- Uso de `mv` en lugar de `ln -s` para asegurar disponibilidad global
- `chmod +x` agregado para asegurar permisos de ejecución

#### Instalación de Specify CLI
- Método oficial desde GitHub en lugar de PyPI (no disponible)
- Funciona correctamente después de rebuild

### Seguridad

- Todas las contraseñas en `.env.example` son placeholders
- PostgreSQL y Redis requieren contraseñas fuertes
- API keys nunca se commitean al repositorio
- `.gitignore` completo para archivos sensibles

## [Unreleased]

### Planeado

- Integración con más MCP servers
- Más workflows de ejemplo
- Tests automatizados del template
- CI/CD con GitHub Actions
- Soporte para más proveedores de LLM
- Dashboard web para auditoría
- Métricas de performance de agentes

---

## Tipos de Cambios

- **Añadido** - para nuevas funcionalidades
- **Cambiado** - para cambios en funcionalidades existentes
- **Deprecado** - para funcionalidades que serán removidas
- **Removido** - para funcionalidades removidas
- **Corregido** - para corrección de bugs
- **Seguridad** - en caso de vulnerabilidades

## Links

- [Repositorio](https://github.com/vtomasv/sdd-dev-template)
- [Issues](https://github.com/vtomasv/sdd-dev-template/issues)
- [Documentación](docs/)
