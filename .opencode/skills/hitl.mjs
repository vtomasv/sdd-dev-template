/**
 * HITL (Human-in-the-Loop) Skill para OpenCode
 * 
 * Este skill permite crear checkpoints de aprobación manual
 * antes de ejecutar acciones críticas.
 */

export const name = "hitl";
export const description = "Human-in-the-Loop checkpoint system for critical operations";

/**
 * Crear un checkpoint de aprobación
 * @param {Object} params - Parámetros del checkpoint
 * @param {string} params.action - Acción que requiere aprobación
 * @param {string} params.description - Descripción detallada
 * @param {string} params.priority - Prioridad: low, medium, high, critical
 * @param {Object} params.context - Contexto adicional
 */
export async function createCheckpoint({ action, description, priority = "medium", context = {} }) {
  const checkpoint = {
    id: `cp-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
    action,
    description,
    priority,
    context,
    status: "pending",
    created_at: new Date().toISOString()
  };

  // Log del checkpoint
  console.log(`\n🔒 HITL Checkpoint Created`);
  console.log(`   ID: ${checkpoint.id}`);
  console.log(`   Action: ${action}`);
  console.log(`   Priority: ${priority}`);
  console.log(`   Description: ${description}`);
  console.log(`\n⏳ Waiting for human approval...`);

  return {
    checkpoint,
    message: `Checkpoint created. Action "${action}" requires human approval before proceeding.`,
    requiresApproval: true
  };
}

/**
 * Verificar estado de un checkpoint
 * @param {string} checkpointId - ID del checkpoint
 */
export async function checkStatus(checkpointId) {
  // En una implementación real, esto consultaría una base de datos o API
  return {
    id: checkpointId,
    status: "pending",
    message: "Checkpoint is awaiting human review"
  };
}

/**
 * Listar checkpoints pendientes
 */
export async function listPending() {
  return {
    checkpoints: [],
    message: "Use 'hitl list' command to see all pending checkpoints"
  };
}

// Exportar todas las funciones como herramientas
export const tools = {
  createCheckpoint: {
    description: "Create a new HITL checkpoint requiring human approval",
    parameters: {
      type: "object",
      properties: {
        action: {
          type: "string",
          description: "The action that requires approval"
        },
        description: {
          type: "string",
          description: "Detailed description of what will happen"
        },
        priority: {
          type: "string",
          enum: ["low", "medium", "high", "critical"],
          description: "Priority level of the checkpoint"
        },
        context: {
          type: "object",
          description: "Additional context for the reviewer"
        }
      },
      required: ["action", "description"]
    }
  },
  checkStatus: {
    description: "Check the status of a HITL checkpoint",
    parameters: {
      type: "object",
      properties: {
        checkpointId: {
          type: "string",
          description: "The ID of the checkpoint to check"
        }
      },
      required: ["checkpointId"]
    }
  },
  listPending: {
    description: "List all pending HITL checkpoints",
    parameters: {
      type: "object",
      properties: {}
    }
  }
};
