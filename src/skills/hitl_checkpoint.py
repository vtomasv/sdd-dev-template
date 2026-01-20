"""
HITL (Human-in-the-Loop) Checkpoint Skill

Implementa checkpoints de aprobación manual siguiendo mejores prácticas de Humanlayer.
Basado en: https://www.humanlayer.dev/
"""
import os
import sys
from datetime import datetime
from typing import Dict, Any, Optional, Literal
from enum import Enum

import psycopg
from loguru import logger
from pydantic import BaseModel, Field


class CheckpointStatus(str, Enum):
    """Estados posibles de un checkpoint"""
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    TIMEOUT = "timeout"


class CheckpointPriority(str, Enum):
    """Prioridad del checkpoint"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class HITLCheckpoint(BaseModel):
    """Modelo de checkpoint HITL"""
    checkpoint_name: str = Field(..., description="Nombre único del checkpoint")
    agent_name: str = Field(..., description="Nombre del agente que solicita aprobación")
    priority: CheckpointPriority = Field(default=CheckpointPriority.MEDIUM)
    data: Dict[str, Any] = Field(default_factory=dict, description="Datos a revisar")
    context: Dict[str, Any] = Field(default_factory=dict, description="Contexto adicional")
    timeout_seconds: Optional[int] = Field(default=None, description="Timeout en segundos")
    notification_channels: list[str] = Field(default_factory=list, description="Canales de notificación")


class HITLCheckpointSkill:
    """Skill para gestionar checkpoints HITL"""
    
    def __init__(self):
        self.db_url = os.getenv("DATABASE_URL")
        self.hitl_enabled = os.getenv("HITL_ENABLED", "true").lower() == "true"
        self.hitl_webhook = os.getenv("HITL_WEBHOOK_URL", "")
        self.slack_webhook = os.getenv("HITL_SLACK_WEBHOOK", "")
        
        if not self.db_url:
            raise ValueError("DATABASE_URL no configurada")
        
        logger.info(f"HITL Checkpoint Skill inicializado (enabled={self.hitl_enabled})")
    
    def create_checkpoint(
        self,
        checkpoint_name: str,
        agent_name: str,
        data: Dict[str, Any],
        priority: CheckpointPriority = CheckpointPriority.MEDIUM,
        context: Optional[Dict[str, Any]] = None,
        timeout_seconds: Optional[int] = None
    ) -> int:
        """
        Crear un nuevo checkpoint HITL
        
        Args:
            checkpoint_name: Nombre único del checkpoint
            agent_name: Nombre del agente que solicita aprobación
            data: Datos a revisar
            priority: Prioridad del checkpoint
            context: Contexto adicional
            timeout_seconds: Timeout en segundos
            
        Returns:
            ID del checkpoint creado
        """
        if not self.hitl_enabled:
            logger.warning("HITL deshabilitado, auto-aprobando checkpoint")
            return -1
        
        try:
            with psycopg.connect(self.db_url) as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO hitl_checkpoints (
                            checkpoint_name,
                            agent_name,
                            status,
                            data,
                            created_at
                        ) VALUES (%s, %s, %s, %s, %s)
                        RETURNING id
                    """, (
                        checkpoint_name,
                        agent_name,
                        CheckpointStatus.PENDING.value,
                        psycopg.types.json.Jsonb({
                            "data": data,
                            "context": context or {},
                            "priority": priority.value,
                            "timeout_seconds": timeout_seconds
                        }),
                        datetime.now()
                    ))
                    checkpoint_id = cur.fetchone()[0]
                    conn.commit()
                    
                    logger.info(f"Checkpoint creado: {checkpoint_name} (ID: {checkpoint_id})")
                    
                    # Notificar
                    self._notify_checkpoint(checkpoint_id, checkpoint_name, agent_name, data, priority)
                    
                    return checkpoint_id
                    
        except Exception as e:
            logger.error(f"Error creando checkpoint: {e}")
            raise
    
    def wait_for_approval(
        self,
        checkpoint_id: int,
        timeout_seconds: Optional[int] = None
    ) -> CheckpointStatus:
        """
        Esperar aprobación de un checkpoint
        
        Args:
            checkpoint_id: ID del checkpoint
            timeout_seconds: Timeout en segundos
            
        Returns:
            Estado final del checkpoint
        """
        if not self.hitl_enabled or checkpoint_id == -1:
            return CheckpointStatus.APPROVED
        
        logger.info(f"Esperando aprobación del checkpoint {checkpoint_id}...")
        
        # En producción, esto debería usar un mecanismo de polling o webhooks
        # Por ahora, simplemente verificamos el estado actual
        try:
            with psycopg.connect(self.db_url) as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT status FROM hitl_checkpoints WHERE id = %s
                    """, (checkpoint_id,))
                    result = cur.fetchone()
                    
                    if result:
                        status = CheckpointStatus(result[0])
                        logger.info(f"Checkpoint {checkpoint_id} status: {status}")
                        return status
                    else:
                        logger.error(f"Checkpoint {checkpoint_id} no encontrado")
                        return CheckpointStatus.TIMEOUT
                        
        except Exception as e:
            logger.error(f"Error verificando checkpoint: {e}")
            return CheckpointStatus.TIMEOUT
    
    def approve_checkpoint(
        self,
        checkpoint_id: int,
        reviewer: str,
        comments: Optional[str] = None
    ) -> bool:
        """
        Aprobar un checkpoint
        
        Args:
            checkpoint_id: ID del checkpoint
            reviewer: Nombre del revisor
            comments: Comentarios opcionales
            
        Returns:
            True si se aprobó correctamente
        """
        return self._update_checkpoint_status(
            checkpoint_id,
            CheckpointStatus.APPROVED,
            reviewer,
            comments
        )
    
    def reject_checkpoint(
        self,
        checkpoint_id: int,
        reviewer: str,
        comments: str
    ) -> bool:
        """
        Rechazar un checkpoint
        
        Args:
            checkpoint_id: ID del checkpoint
            reviewer: Nombre del revisor
            comments: Comentarios (requeridos para rechazo)
            
        Returns:
            True si se rechazó correctamente
        """
        return self._update_checkpoint_status(
            checkpoint_id,
            CheckpointStatus.REJECTED,
            reviewer,
            comments
        )
    
    def _update_checkpoint_status(
        self,
        checkpoint_id: int,
        status: CheckpointStatus,
        reviewer: str,
        comments: Optional[str] = None
    ) -> bool:
        """Actualizar estado de un checkpoint"""
        try:
            with psycopg.connect(self.db_url) as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        UPDATE hitl_checkpoints
                        SET status = %s,
                            reviewed_at = %s,
                            reviewer = %s,
                            comments = %s
                        WHERE id = %s
                    """, (
                        status.value,
                        datetime.now(),
                        reviewer,
                        comments,
                        checkpoint_id
                    ))
                    conn.commit()
                    
                    logger.info(f"Checkpoint {checkpoint_id} {status.value} por {reviewer}")
                    
                    # Registrar en audit log
                    self._log_checkpoint_decision(checkpoint_id, status, reviewer, comments)
                    
                    return True
                    
        except Exception as e:
            logger.error(f"Error actualizando checkpoint: {e}")
            return False
    
    def get_pending_checkpoints(self) -> list[Dict[str, Any]]:
        """Obtener todos los checkpoints pendientes"""
        try:
            with psycopg.connect(self.db_url) as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT id, checkpoint_name, agent_name, data, created_at
                        FROM hitl_checkpoints
                        WHERE status = %s
                        ORDER BY created_at DESC
                    """, (CheckpointStatus.PENDING.value,))
                    
                    checkpoints = []
                    for row in cur.fetchall():
                        checkpoints.append({
                            "id": row[0],
                            "checkpoint_name": row[1],
                            "agent_name": row[2],
                            "data": row[3],
                            "created_at": row[4].isoformat()
                        })
                    
                    return checkpoints
                    
        except Exception as e:
            logger.error(f"Error obteniendo checkpoints pendientes: {e}")
            return []
    
    def _notify_checkpoint(
        self,
        checkpoint_id: int,
        checkpoint_name: str,
        agent_name: str,
        data: Dict[str, Any],
        priority: CheckpointPriority
    ):
        """Notificar creación de checkpoint"""
        message = f"""
🔔 Nuevo Checkpoint HITL

**ID**: {checkpoint_id}
**Nombre**: {checkpoint_name}
**Agente**: {agent_name}
**Prioridad**: {priority.value}

**Datos**:
```json
{data}
```

Para aprobar: `python src/skills/hitl_checkpoint.py approve {checkpoint_id} <reviewer>`
Para rechazar: `python src/skills/hitl_checkpoint.py reject {checkpoint_id} <reviewer> "<comentarios>"`
"""
        
        logger.info(message)
        
        # Aquí se pueden agregar notificaciones a Slack, email, etc.
        if self.slack_webhook:
            self._send_slack_notification(message)
    
    def _send_slack_notification(self, message: str):
        """Enviar notificación a Slack"""
        try:
            import requests
            requests.post(self.slack_webhook, json={"text": message}, timeout=5)
        except Exception as e:
            logger.warning(f"Error enviando notificación a Slack: {e}")
    
    def _log_checkpoint_decision(
        self,
        checkpoint_id: int,
        status: CheckpointStatus,
        reviewer: str,
        comments: Optional[str]
    ):
        """Registrar decisión en audit log"""
        try:
            with psycopg.connect(self.db_url) as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO audit_log (
                            agent_name,
                            action,
                            decision,
                            context,
                            reasoning,
                            confidence,
                            session_id
                        ) VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """, (
                        "hitl_system",
                        f"checkpoint_{status.value}",
                        f"Checkpoint {checkpoint_id} {status.value}",
                        psycopg.types.json.Jsonb({
                            "checkpoint_id": checkpoint_id,
                            "reviewer": reviewer,
                            "comments": comments
                        }),
                        comments or f"Checkpoint {status.value} por {reviewer}",
                        1.0,
                        os.getenv("SESSION_ID", "unknown")
                    ))
                    conn.commit()
        except Exception as e:
            logger.error(f"Error registrando en audit log: {e}")


# CLI para gestión manual de checkpoints
def main():
    """CLI para gestión de checkpoints"""
    import sys
    
    skill = HITLCheckpointSkill()
    
    if len(sys.argv) < 2:
        print("Uso:")
        print("  python hitl_checkpoint.py list                          # Listar pendientes")
        print("  python hitl_checkpoint.py approve <id> <reviewer>       # Aprobar")
        print("  python hitl_checkpoint.py reject <id> <reviewer> <msg>  # Rechazar")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "list":
        checkpoints = skill.get_pending_checkpoints()
        if not checkpoints:
            print("No hay checkpoints pendientes")
        else:
            print(f"\n📋 {len(checkpoints)} checkpoint(s) pendiente(s):\n")
            for cp in checkpoints:
                print(f"ID: {cp['id']}")
                print(f"Nombre: {cp['checkpoint_name']}")
                print(f"Agente: {cp['agent_name']}")
                print(f"Creado: {cp['created_at']}")
                print(f"Datos: {cp['data']}")
                print("-" * 50)
    
    elif command == "approve":
        if len(sys.argv) < 4:
            print("Uso: python hitl_checkpoint.py approve <id> <reviewer>")
            sys.exit(1)
        
        checkpoint_id = int(sys.argv[2])
        reviewer = sys.argv[3]
        
        if skill.approve_checkpoint(checkpoint_id, reviewer):
            print(f"✅ Checkpoint {checkpoint_id} aprobado por {reviewer}")
        else:
            print(f"❌ Error aprobando checkpoint {checkpoint_id}")
    
    elif command == "reject":
        if len(sys.argv) < 5:
            print("Uso: python hitl_checkpoint.py reject <id> <reviewer> <comentarios>")
            sys.exit(1)
        
        checkpoint_id = int(sys.argv[2])
        reviewer = sys.argv[3]
        comments = " ".join(sys.argv[4:])
        
        if skill.reject_checkpoint(checkpoint_id, reviewer, comments):
            print(f"❌ Checkpoint {checkpoint_id} rechazado por {reviewer}")
        else:
            print(f"❌ Error rechazando checkpoint {checkpoint_id}")
    
    else:
        print(f"Comando desconocido: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()
