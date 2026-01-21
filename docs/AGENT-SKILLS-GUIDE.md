# Agent Skills Guide

Esta guía explica cómo funcionan los Agent Skills en el template SDD y cómo usarlos con OpenCode y otros agentes de IA.

## ¿Qué son los Agent Skills?

Los Agent Skills son módulos de código que extienden las capacidades de los agentes de IA. Permiten que los agentes ejecuten acciones específicas como crear checkpoints HITL, registrar decisiones en el audit log, o gestionar especificaciones del proyecto.

## Estructura de Skills

El template incluye tres skills principales ubicados en `.opencode/skills/`:

| Skill | Archivo | Propósito |
|-------|---------|-----------|
| HITL | `hitl.mjs` | Checkpoints de aprobación manual |
| Audit | `audit.mjs` | Registro de decisiones y acciones |
| Spec | `spec.mjs` | Gestión de especificaciones SDD |

## Configuración

Los skills se configuran en `.opencode/config.json`:

```json
{
  "skills": {
    "enabled": true,
    "directory": ".opencode/skills",
    "autoload": true,
    "skills": [
      { "name": "hitl", "file": "hitl.mjs", "enabled": true },
      { "name": "audit", "file": "audit.mjs", "enabled": true },
      { "name": "spec", "file": "spec.mjs", "enabled": true }
    ]
  }
}
```

## Skill: HITL (Human-in-the-Loop)

Este skill permite crear checkpoints que requieren aprobación humana antes de continuar.

### Funciones Disponibles

**createCheckpoint**: Crea un nuevo checkpoint de aprobación.

```javascript
// Ejemplo de uso interno
await hitl.createCheckpoint({
  action: "delete_database",
  description: "Eliminar tabla users de producción",
  priority: "critical",
  context: { table: "users", environment: "production" }
});
```

**checkStatus**: Verifica el estado de un checkpoint existente.

**listPending**: Lista todos los checkpoints pendientes de aprobación.

### Cuándo se Activa

El skill HITL se activa automáticamente para operaciones críticas definidas en la configuración, incluyendo eliminación de archivos, modificación de configuraciones, deployments, migraciones de base de datos y cambios de seguridad.

## Skill: Audit

Este skill registra todas las decisiones y acciones del agente para trazabilidad.

### Funciones Disponibles

**logDecision**: Registra una decisión tomada por el agente.

```javascript
await audit.logDecision({
  decision: "Usar PostgreSQL en lugar de MySQL",
  reasoning: "Mejor soporte para JSON y extensiones",
  category: "architecture"
});
```

**logAction**: Registra una acción ejecutada.

```javascript
await audit.logAction({
  action: "Crear archivo models.py",
  result: "Archivo creado con 3 modelos",
  status: "success"
});
```

**logError**: Registra un error ocurrido.

**getSummary**: Obtiene un resumen del log de auditoría.

### Archivo de Log

Todas las entradas se guardan en `.local/audit/decisions.jsonl` en formato JSON Lines, lo que permite fácil análisis y búsqueda.

## Skill: Spec

Este skill gestiona las especificaciones del proyecto siguiendo la metodología SDD.

### Funciones Disponibles

**setConstitution**: Crea o actualiza la constitución del proyecto con principios y reglas.

**getConstitution**: Obtiene la constitución actual.

**setSpecification**: Crea o actualiza la especificación del proyecto con requisitos funcionales y no funcionales.

**getSpecification**: Obtiene la especificación actual.

**setPlan**: Crea o actualiza el plan técnico con arquitectura, fases y milestones.

**setTasks**: Crea o actualiza la lista de tareas.

### Archivos Generados

Los archivos se guardan en `.speckit/memory/`:

| Archivo | Contenido |
|---------|-----------|
| `constitution.md` | Principios y reglas del proyecto |
| `specification.md` | Requisitos funcionales y no funcionales |
| `plan.md` | Arquitectura y fases de implementación |
| `tasks.md` | Lista de tareas con checkboxes |

## Uso con OpenCode

Para usar los skills en OpenCode, primero asegúrate de que el proyecto esté inicializado:

```bash
# Dentro del contenedor dev
specify init . --ai opencode --force
```

Luego, en OpenCode, puedes usar los comandos `/speckit.*`:

```
/speckit.constitution Crear principios de calidad de código
/speckit.specify Construir una API REST para gestión de tareas
/speckit.plan Usar FastAPI con PostgreSQL
/speckit.tasks
/speckit.implement
```

## Uso con Claude Code

Para Claude Code, los skills funcionan a través de los agentes definidos en `.claude/agents/`. Cada agente tiene instrucciones específicas para usar los skills apropiados.

## Crear Skills Personalizados

Puedes crear tus propios skills siguiendo esta estructura:

```javascript
// .opencode/skills/mi-skill.mjs

export const name = "mi-skill";
export const description = "Descripción del skill";

export async function miFuncion({ param1, param2 }) {
  // Implementación
  return { resultado: "valor" };
}

export const tools = {
  miFuncion: {
    description: "Descripción de la función",
    parameters: {
      type: "object",
      properties: {
        param1: { type: "string", description: "..." },
        param2: { type: "number", description: "..." }
      },
      required: ["param1"]
    }
  }
};
```

Luego, agrégalo a `.opencode/config.json`:

```json
{
  "skills": {
    "skills": [
      // ... skills existentes
      { "name": "mi-skill", "file": "mi-skill.mjs", "enabled": true }
    ]
  }
}
```

## Troubleshooting

### Skills no se cargan

Verifica que los archivos `.mjs` tengan la sintaxis correcta de ES modules y que estén listados en `config.json`.

### Error "tool unavailable"

Este error indica que OpenCode no reconoce el skill. Asegúrate de haber ejecutado `specify init . --ai opencode --force` y reinicia OpenCode.

### Audit log vacío

Verifica que el directorio `.local/audit/` existe y tiene permisos de escritura.

## Referencias

Para más información sobre Agent Skills, consulta la documentación de OpenCode en [opencode.ai](https://opencode.ai/) y la guía de Spec Kit en [github.com/github/spec-kit](https://github.com/github/spec-kit).
