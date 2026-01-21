/**
 * Audit Skill para OpenCode
 * 
 * Este skill registra todas las decisiones y acciones del agente
 * para trazabilidad y compliance.
 */

export const name = "audit";
export const description = "Audit logging system for AI agent decisions and actions";

import { writeFileSync, appendFileSync, existsSync, mkdirSync } from 'fs';
import { join } from 'path';

const AUDIT_DIR = '.local/audit';
const AUDIT_FILE = 'decisions.jsonl';

/**
 * Asegurar que el directorio de auditoría existe
 */
function ensureAuditDir() {
  if (!existsSync(AUDIT_DIR)) {
    mkdirSync(AUDIT_DIR, { recursive: true });
  }
}

/**
 * Registrar una decisión del agente
 * @param {Object} params - Parámetros de la decisión
 * @param {string} params.decision - Descripción de la decisión
 * @param {string} params.reasoning - Razonamiento detrás de la decisión
 * @param {string} params.category - Categoría: code, architecture, security, etc.
 * @param {Object} params.context - Contexto adicional
 */
export async function logDecision({ decision, reasoning, category = "general", context = {} }) {
  ensureAuditDir();
  
  const entry = {
    id: `dec-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
    timestamp: new Date().toISOString(),
    type: "decision",
    decision,
    reasoning,
    category,
    context,
    agent: "opencode"
  };

  const filePath = join(AUDIT_DIR, AUDIT_FILE);
  appendFileSync(filePath, JSON.stringify(entry) + '\n');

  console.log(`📝 Decision logged: ${decision}`);
  
  return {
    logged: true,
    entryId: entry.id,
    message: `Decision "${decision}" has been logged for audit`
  };
}

/**
 * Registrar una acción ejecutada
 * @param {Object} params - Parámetros de la acción
 * @param {string} params.action - Acción ejecutada
 * @param {string} params.result - Resultado de la acción
 * @param {string} params.status - Estado: success, failure, partial
 * @param {Object} params.metadata - Metadatos adicionales
 */
export async function logAction({ action, result, status = "success", metadata = {} }) {
  ensureAuditDir();
  
  const entry = {
    id: `act-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
    timestamp: new Date().toISOString(),
    type: "action",
    action,
    result,
    status,
    metadata,
    agent: "opencode"
  };

  const filePath = join(AUDIT_DIR, AUDIT_FILE);
  appendFileSync(filePath, JSON.stringify(entry) + '\n');

  console.log(`✅ Action logged: ${action} (${status})`);
  
  return {
    logged: true,
    entryId: entry.id,
    message: `Action "${action}" has been logged with status "${status}"`
  };
}

/**
 * Registrar un error
 * @param {Object} params - Parámetros del error
 * @param {string} params.error - Descripción del error
 * @param {string} params.stack - Stack trace (opcional)
 * @param {Object} params.context - Contexto del error
 */
export async function logError({ error, stack = "", context = {} }) {
  ensureAuditDir();
  
  const entry = {
    id: `err-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
    timestamp: new Date().toISOString(),
    type: "error",
    error,
    stack,
    context,
    agent: "opencode"
  };

  const filePath = join(AUDIT_DIR, AUDIT_FILE);
  appendFileSync(filePath, JSON.stringify(entry) + '\n');

  console.log(`❌ Error logged: ${error}`);
  
  return {
    logged: true,
    entryId: entry.id,
    message: `Error "${error}" has been logged for review`
  };
}

/**
 * Obtener resumen de auditoría
 */
export async function getSummary() {
  ensureAuditDir();
  const filePath = join(AUDIT_DIR, AUDIT_FILE);
  
  if (!existsSync(filePath)) {
    return {
      totalEntries: 0,
      decisions: 0,
      actions: 0,
      errors: 0,
      message: "No audit entries found"
    };
  }

  // En una implementación real, esto leería y parseara el archivo
  return {
    message: "Use 'cat .local/audit/decisions.jsonl' to view audit log",
    filePath
  };
}

// Exportar todas las funciones como herramientas
export const tools = {
  logDecision: {
    description: "Log an AI agent decision for audit trail",
    parameters: {
      type: "object",
      properties: {
        decision: {
          type: "string",
          description: "Description of the decision made"
        },
        reasoning: {
          type: "string",
          description: "Reasoning behind the decision"
        },
        category: {
          type: "string",
          enum: ["code", "architecture", "security", "testing", "deployment", "general"],
          description: "Category of the decision"
        },
        context: {
          type: "object",
          description: "Additional context"
        }
      },
      required: ["decision", "reasoning"]
    }
  },
  logAction: {
    description: "Log an executed action for audit trail",
    parameters: {
      type: "object",
      properties: {
        action: {
          type: "string",
          description: "The action that was executed"
        },
        result: {
          type: "string",
          description: "Result of the action"
        },
        status: {
          type: "string",
          enum: ["success", "failure", "partial"],
          description: "Status of the action"
        },
        metadata: {
          type: "object",
          description: "Additional metadata"
        }
      },
      required: ["action", "result"]
    }
  },
  logError: {
    description: "Log an error for audit trail",
    parameters: {
      type: "object",
      properties: {
        error: {
          type: "string",
          description: "Description of the error"
        },
        stack: {
          type: "string",
          description: "Stack trace if available"
        },
        context: {
          type: "object",
          description: "Context when error occurred"
        }
      },
      required: ["error"]
    }
  },
  getSummary: {
    description: "Get a summary of the audit log",
    parameters: {
      type: "object",
      properties: {}
    }
  }
};
