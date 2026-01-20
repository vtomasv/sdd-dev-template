# Guía de Claude Code Workflow Studio

Esta guía explica cómo usar **Claude Code Workflow Studio** (cc-wf-studio) para diseñar workflows visuales de automatización con agentes de IA en el template SDD.

## ¿Qué es cc-wf-studio?

**Claude Code Workflow Studio** es una extensión de VSCode que permite diseñar workflows complejos de agentes de IA de forma visual, sin escribir código. Los workflows se exportan directamente a formato `.claude` para ejecución inmediata.

### Características Principales

- **Editor Visual Drag-and-Drop**: Diseña workflows arrastrando nodos
- **Edición con IA**: Refina workflows usando lenguaje natural
- **Exportación Directa**: Genera archivos `.claude/agents/*.md` y `.claude/commands/*.md`
- **Integración MCP**: Usa herramientas externas (GitHub, Slack, etc.)
- **HITL Integrado**: Agrega checkpoints de aprobación manual
- **Compartir en Slack**: Exporta workflows con preview cards

## Instalación

### Opción 1: Desde VSCode Marketplace

1. Abre VSCode
2. Ve a Extensions (`Ctrl+Shift+X` / `Cmd+Shift+X`)
3. Busca "Claude Code Workflow Studio"
4. Click en **Install**

### Opción 2: Desde Open VSX

```bash
code --install-extension breaking-brake.cc-wf-studio
```

### Opción 3: El template ya lo recomienda

El archivo `.vscode/extensions.json` ya incluye cc-wf-studio en las recomendaciones. VSCode te sugerirá instalarlo automáticamente.

## Primeros Pasos

### 1. Abrir el Editor

1. Presiona `Ctrl+Shift+P` / `Cmd+Shift+P`
2. Escribe "Claude Code Workflow Studio: Open Editor"
3. Presiona Enter

### 2. Crear un Workflow Nuevo

**Opción A: Desde Cero**

1. Click en "New Workflow"
2. Arrastra nodos desde el panel izquierdo
3. Conecta nodos arrastrando desde los puertos
4. Configura cada nodo con doble click

**Opción B: Con IA (Recomendado)**

1. Click en el botón "✨ Generate with AI"
2. Describe tu workflow en lenguaje natural:
   ```
   Crea un workflow de code review que:
   1. Obtenga detalles del PR desde GitHub
   2. Analice el código con el review-agent
   3. Si el score es >= 80, apruebe el PR
   4. Si no, solicite cambios
   5. Notifique en Slack
   6. Registre en auditoría
   ```
3. Click "Generate"
4. Revisa y refina el workflow generado

### 3. Refinar con IA

Puedes mejorar workflows existentes iterativamente:

1. Abre un workflow existente
2. Click en "✨ Edit with AI"
3. Describe los cambios:
   ```
   Agrega un checkpoint HITL antes de aprobar el PR
   ```
4. Click "Apply Changes"
5. Repite hasta estar satisfecho

### 4. Exportar el Workflow

1. Click en "Export" en la barra superior
2. Selecciona formato:
   - **Claude Code** (recomendado para SDD)
   - **GitHub Copilot**
   - **JSON** (para compartir)
3. El workflow se guarda en `.claude/workflows/`

## Tipos de Nodos

### Prompt
Define el input inicial del workflow.

```json
{
  "type": "Prompt",
  "data": {
    "label": "User Input",
    "template": "Task: {{task}}\nContext: {{context}}"
  }
}
```

### SubAgent
Ejecuta un agente de IA para una tarea específica.

```json
{
  "type": "SubAgent",
  "data": {
    "label": "Spec Agent",
    "agentPath": ".claude/agents/spec-agent.md",
    "systemPrompt": "Generate technical specification"
  }
}
```

### Skill
Ejecuta una Claude Code Skill (función Python).

```json
{
  "type": "Skill",
  "data": {
    "label": "HITL Checkpoint",
    "skillName": "hitl_checkpoint",
    "parameters": {
      "checkpoint_name": "spec_approval",
      "priority": "HIGH"
    }
  }
}
```

### MCP
Usa herramientas externas vía Model Context Protocol.

```json
{
  "type": "MCP",
  "data": {
    "label": "Fetch PR",
    "server": "github",
    "tool": "get_pull_request",
    "parameters": {
      "owner": "{{repo_owner}}",
      "repo": "{{repo_name}}",
      "pull_number": "{{pr_number}}"
    }
  }
}
```

### IfElse
Ramificación condicional simple (2 caminos).

```json
{
  "type": "IfElse",
  "data": {
    "label": "Quality Gate",
    "condition": "score >= 80"
  }
}
```

### Switch
Ramificación múltiple (3+ caminos).

```json
{
  "type": "Switch",
  "data": {
    "label": "Priority Router",
    "variable": "priority",
    "cases": ["HIGH", "MEDIUM", "LOW"]
  }
}
```

### AskUserQuestion
Checkpoint HITL para decisión manual.

```json
{
  "type": "AskUserQuestion",
  "data": {
    "label": "Approve Spec?",
    "question": "Review the specification. Approve?",
    "options": ["Approve", "Request Changes", "Reject"]
  }
}
```

## Workflows de Ejemplo Incluidos

El template incluye 4 workflows de ejemplo en `.claude/workflows/`:

### 1. spec-generation.json
Genera especificaciones técnicas con aprobación HITL.

**Flujo**:
1. Input de requisitos
2. Spec Agent genera especificación
3. HITL: ¿Aprobar?
   - Aprobar → Guardar spec
   - Cambios → Refinar spec → Volver a HITL
   - Rechazar → Fin
4. Registrar en auditoría

**Uso**:
```bash
# Abrir en cc-wf-studio
code .claude/workflows/spec-generation.json
```

### 2. code-review.json
Revisión automatizada de código con quality gate.

**Flujo**:
1. Input de código
2. Review Agent analiza código
3. Quality Gate: ¿Score >= 80?
   - Sí → Generar reporte de aprobación
   - No → Generar lista de issues
4. HITL: ¿Aprobar para merge?
5. Registrar en auditoría

### 3. mcp-integration.json
Workflow con integraciones externas (GitHub + Slack).

**Flujo**:
1. Input de tarea
2. MCP: Fetch PR details desde GitHub
3. Review Agent analiza código
4. Quality Gate: ¿Score >= 80 y sin issues de seguridad?
   - Sí → MCP: Aprobar PR en GitHub
   - No → MCP: Request changes en GitHub
5. MCP: Notificar en Slack
6. Registrar en auditoría

### 4. local-llm-workflow.json
Procesamiento de datos sensibles con Ollama (local).

**Flujo**:
1. Input de datos sensibles
2. HITL: ¿Procesar localmente con Ollama?
   - Sí → Skill: ollama_generate
   - No → SubAgent: Cloud LLM con encriptación
3. Review Agent valida output
4. Security Check: ¿Tiene datos sensibles?
   - No → Aprobar y guardar
   - Sí → Redactar información sensible
5. Registrar en auditoría

## Integración con Ollama

Los workflows pueden usar Ollama para procesamiento local:

### Configurar Modelo

En el nodo Skill:

```json
{
  "type": "Skill",
  "data": {
    "label": "Process with Ollama",
    "skillName": "ollama_generate",
    "parameters": {
      "prompt": "{{input}}",
      "model": "qwen2.5-coder:latest",
      "temperature": 0.3,
      "max_tokens": 2000
    }
  }
}
```

### Modelos Recomendados

| Modelo | Tamaño | Uso | Velocidad |
|--------|--------|-----|-----------|
| `llama3.2:latest` | 8B | General | ⚡⚡⚡ |
| `qwen2.5-coder:latest` | 7B | Código | ⚡⚡⚡ |
| `codellama:latest` | 7B | Código | ⚡⚡ |
| `mistral:latest` | 7B | Razonamiento | ⚡⚡ |
| `deepseek-coder:latest` | 6.7B | Código | ⚡⚡⚡ |

### Ventajas de Ollama en Workflows

- ✅ **Privacidad**: Datos sensibles no salen del servidor
- ✅ **Costo**: Sin límites de API
- ✅ **Latencia**: Procesamiento local más rápido
- ✅ **Offline**: Funciona sin internet

## Integración con MCP

Los workflows pueden usar MCP tools para integraciones externas.

### Configurar MCP Server

1. Instala el MCP server:
   ```bash
   npm install -g @modelcontextprotocol/server-github
   ```

2. Configura en `.claude/mcp.json`:
   ```json
   {
     "mcpServers": {
       "github": {
         "command": "npx",
         "args": ["-y", "@modelcontextprotocol/server-github"],
         "env": {
           "GITHUB_TOKEN": "${GITHUB_TOKEN}"
         }
       }
     }
   }
   ```

### Usar MCP en Workflow

```json
{
  "type": "MCP",
  "data": {
    "label": "Create GitHub Issue",
    "server": "github",
    "tool": "create_issue",
    "parameters": {
      "owner": "vtomasv",
      "repo": "sdd-dev-template",
      "title": "{{issue_title}}",
      "body": "{{issue_body}}"
    }
  }
}
```

### MCP Servers Recomendados

- **GitHub**: `@modelcontextprotocol/server-github`
- **Slack**: `@modelcontextprotocol/server-slack`
- **Google Drive**: `@modelcontextprotocol/server-gdrive`
- **PostgreSQL**: `@modelcontextprotocol/server-postgres`

## Mejores Prácticas

### 1. Diseño Modular

Divide workflows complejos en sub-workflows reutilizables:

```
workflow-principal.json
├── sub-workflow-1.json (validación)
├── sub-workflow-2.json (procesamiento)
└── sub-workflow-3.json (notificación)
```

### 2. Checkpoints HITL Estratégicos

Agrega HITL en puntos críticos:

- ✅ Antes de operaciones destructivas (delete, deploy)
- ✅ Después de generar especificaciones
- ✅ Antes de aprobar PRs
- ✅ Antes de notificaciones masivas

### 3. Auditoría Completa

Siempre termina workflows con nodo de auditoría:

```json
{
  "type": "Skill",
  "data": {
    "label": "Audit Log",
    "skillName": "audit_logger",
    "parameters": {
      "agent_name": "{{workflow_name}}",
      "action": "{{action}}",
      "decision": "{{decision}}"
    }
  }
}
```

### 4. Manejo de Errores

Agrega nodos de error handling:

```json
{
  "type": "IfElse",
  "data": {
    "label": "Error Check",
    "condition": "error === null"
  }
}
```

### 5. Variables Claras

Usa nombres descriptivos para variables:

```
❌ {{x}}, {{data}}, {{result}}
✅ {{pr_number}}, {{review_score}}, {{approval_status}}
```

## Compartir Workflows

### Exportar a JSON

1. Click en "Export" → "JSON"
2. Comparte el archivo `.json`
3. Otros pueden importarlo con "Import" → "From JSON"

### Compartir en Slack (Beta)

1. Click en "Share" → "Slack"
2. Selecciona canal
3. Se genera preview card con botón "Import"
4. Otros pueden importar con 1 click

### Publicar en GitHub

Commitea workflows a `.claude/workflows/` para compartir con el equipo:

```bash
git add .claude/workflows/
git commit -m "Add new workflow: automated-deployment"
git push
```

## Troubleshooting

### Workflow no se exporta

**Problema**: Click en "Export" no hace nada

**Solución**:
1. Verifica que todos los nodos estén conectados
2. Verifica que no haya ciclos infinitos
3. Revisa la consola de VSCode (Help → Toggle Developer Tools)

### MCP tool no funciona

**Problema**: Nodo MCP falla en ejecución

**Solución**:
1. Verifica que el MCP server esté instalado
2. Verifica configuración en `.claude/mcp.json`
3. Verifica que las credenciales estén en `.env`

### Ollama no responde

**Problema**: Nodo Skill con Ollama timeout

**Solución**:
1. Verifica que Ollama esté corriendo:
   ```bash
   docker compose ps ollama
   ```
2. Verifica que el modelo esté descargado:
   ```bash
   docker compose exec ollama ollama list
   ```
3. Descarga el modelo si falta:
   ```bash
   bash scripts/05_setup-ollama.sh
   ```

### IA no genera workflow correcto

**Problema**: "Generate with AI" produce workflow incorrecto

**Solución**:
1. Sé más específico en la descripción
2. Menciona tipos de nodos exactos
3. Divide en requests más pequeños
4. Usa "Edit with AI" para refinar iterativamente

## Recursos Adicionales

- **Repositorio**: https://github.com/breaking-brake/cc-wf-studio
- **Documentación oficial**: https://github.com/breaking-brake/cc-wf-studio/blob/main/README.md
- **Issues**: https://github.com/breaking-brake/cc-wf-studio/issues
- **Ejemplos**: `.claude/workflows/` en este template

## Próximos Pasos

1. ✅ Instala cc-wf-studio desde VSCode Marketplace
2. ✅ Abre uno de los workflows de ejemplo
3. ✅ Experimenta con "Edit with AI"
4. ✅ Crea tu primer workflow personalizado
5. ✅ Exporta y ejecuta con Claude Code

¡Disfruta diseñando workflows visuales! 🎨🤖
