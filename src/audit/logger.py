"""
Sistema de Auditoría para Decisiones de IA

Registra todas las decisiones de agentes de IA para trazabilidad y compliance.
Basado en mejores prácticas de: https://www.humanlayer.dev/
"""
import os
import json
from datetime import datetime
from typing import Dict, Any, Optional, List
from pathlib import Path

import psycopg
from loguru import logger as loguru_logger
from pydantic import BaseModel, Field


class AgentDecision(BaseModel):
    """Modelo de decisión de agente"""
    agent_name: str = Field(..., description="Nombre del agente")
    action: str = Field(..., description="Acción realizada")
    decision: str = Field(..., description="Decisión tomada")
    context: Dict[str, Any] = Field(default_factory=dict, description="Contexto de la decisión")
    reasoning: Optional[str] = Field(None, description="Razonamiento detrás de la decisión")
    confidence: float = Field(default=1.0, ge=0.0, le=1.0, description="Confianza en la decisión")
    session_id: Optional[str] = Field(None, description="ID de sesión")
    user_id: Optional[str] = Field(None, description="ID de usuario")
    timestamp: datetime = Field(default_factory=datetime.now)


class AuditLogger:
    """Logger centralizado para auditoría de decisiones de IA"""
    
    def __init__(self):
        self.db_url = os.getenv("DATABASE_URL")
        self.audit_enabled = os.getenv("AUDIT_DB_ENABLED", "true").lower() == "true"
        self.file_enabled = os.getenv("AUDIT_FILE_ENABLED", "true").lower() == "true"
        self.log_path = Path(os.getenv("AUDIT_LOG_PATH", ".local/audit/logs"))
        self.session_id = os.getenv("SESSION_ID", "unknown")
        
        if not self.db_url and self.audit_enabled:
            raise ValueError("DATABASE_URL no configurada pero AUDIT_DB_ENABLED=true")
        
        # Crear directorio de logs si no existe
        if self.file_enabled:
            self.log_path.mkdir(parents=True, exist_ok=True)
        
        loguru_logger.info(f"Audit Logger inicializado (db={self.audit_enabled}, file={self.file_enabled})")
    
    def log_decision(
        self,
        agent_name: str,
        action: str,
        decision: str,
        context: Optional[Dict[str, Any]] = None,
        reasoning: Optional[str] = None,
        confidence: float = 1.0,
        user_id: Optional[str] = None
    ) -> bool:
        """
        Registrar una decisión de agente
        
        Args:
            agent_name: Nombre del agente que toma la decisión
            action: Acción realizada
            decision: Decisión tomada
            context: Contexto adicional
            reasoning: Razonamiento detrás de la decisión
            confidence: Confianza en la decisión (0.0-1.0)
            user_id: ID de usuario (opcional)
            
        Returns:
            True si se registró correctamente
        """
        try:
            decision_obj = AgentDecision(
                agent_name=agent_name,
                action=action,
                decision=decision,
                context=context or {},
                reasoning=reasoning,
                confidence=confidence,
                session_id=self.session_id,
                user_id=user_id
            )
            
            # Log a base de datos
            if self.audit_enabled:
                self._log_to_db(decision_obj)
            
            # Log a archivo
            if self.file_enabled:
                self._log_to_file(decision_obj)
            
            loguru_logger.info(f"Decisión registrada: {agent_name} - {action}")
            return True
            
        except Exception as e:
            loguru_logger.error(f"Error registrando decisión: {e}")
            return False
    
    def _log_to_db(self, decision: AgentDecision):
        """Registrar decisión en PostgreSQL"""
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
                            timestamp,
                            session_id,
                            user_id
                        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """, (
                        decision.agent_name,
                        decision.action,
                        decision.decision,
                        psycopg.types.json.Jsonb(decision.context),
                        decision.reasoning,
                        decision.confidence,
                        decision.timestamp,
                        decision.session_id,
                        decision.user_id
                    ))
                    conn.commit()
        except Exception as e:
            loguru_logger.error(f"Error escribiendo a DB: {e}")
            raise
    
    def _log_to_file(self, decision: AgentDecision):
        """Registrar decisión en archivo JSON"""
        try:
            # Archivo por día
            log_file = self.log_path / f"audit_{datetime.now().strftime('%Y%m%d')}.jsonl"
            
            with open(log_file, "a") as f:
                f.write(json.dumps({
                    "agent_name": decision.agent_name,
                    "action": decision.action,
                    "decision": decision.decision,
                    "context": decision.context,
                    "reasoning": decision.reasoning,
                    "confidence": decision.confidence,
                    "timestamp": decision.timestamp.isoformat(),
                    "session_id": decision.session_id,
                    "user_id": decision.user_id
                }) + "\n")
        except Exception as e:
            loguru_logger.error(f"Error escribiendo a archivo: {e}")
    
    def get_recent_decisions(
        self,
        limit: int = 20,
        agent_name: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Obtener decisiones recientes
        
        Args:
            limit: Número máximo de decisiones a retornar
            agent_name: Filtrar por nombre de agente (opcional)
            
        Returns:
            Lista de decisiones
        """
        if not self.audit_enabled:
            return []
        
        try:
            with psycopg.connect(self.db_url) as conn:
                with conn.cursor() as cur:
                    if agent_name:
                        cur.execute("""
                            SELECT id, agent_name, action, decision, context, 
                                   reasoning, confidence, timestamp, session_id
                            FROM audit_log
                            WHERE agent_name = %s
                            ORDER BY timestamp DESC
                            LIMIT %s
                        """, (agent_name, limit))
                    else:
                        cur.execute("""
                            SELECT id, agent_name, action, decision, context, 
                                   reasoning, confidence, timestamp, session_id
                            FROM audit_log
                            ORDER BY timestamp DESC
                            LIMIT %s
                        """, (limit,))
                    
                    decisions = []
                    for row in cur.fetchall():
                        decisions.append({
                            "id": row[0],
                            "agent_name": row[1],
                            "action": row[2],
                            "decision": row[3],
                            "context": row[4],
                            "reasoning": row[5],
                            "confidence": row[6],
                            "timestamp": row[7].isoformat(),
                            "session_id": row[8]
                        })
                    
                    return decisions
        except Exception as e:
            loguru_logger.error(f"Error obteniendo decisiones: {e}")
            return []
    
    def get_decisions_by_session(self, session_id: str) -> List[Dict[str, Any]]:
        """Obtener todas las decisiones de una sesión"""
        if not self.audit_enabled:
            return []
        
        try:
            with psycopg.connect(self.db_url) as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT id, agent_name, action, decision, context, 
                               reasoning, confidence, timestamp
                        FROM audit_log
                        WHERE session_id = %s
                        ORDER BY timestamp ASC
                    """, (session_id,))
                    
                    decisions = []
                    for row in cur.fetchall():
                        decisions.append({
                            "id": row[0],
                            "agent_name": row[1],
                            "action": row[2],
                            "decision": row[3],
                            "context": row[4],
                            "reasoning": row[5],
                            "confidence": row[6],
                            "timestamp": row[7].isoformat()
                        })
                    
                    return decisions
        except Exception as e:
            loguru_logger.error(f"Error obteniendo decisiones por sesión: {e}")
            return []
    
    def get_statistics(self) -> Dict[str, Any]:
        """Obtener estadísticas de auditoría"""
        if not self.audit_enabled:
            return {}
        
        try:
            with psycopg.connect(self.db_url) as conn:
                with conn.cursor() as cur:
                    # Total de decisiones
                    cur.execute("SELECT COUNT(*) FROM audit_log")
                    total = cur.fetchone()[0]
                    
                    # Decisiones por agente
                    cur.execute("""
                        SELECT agent_name, COUNT(*) as count
                        FROM audit_log
                        GROUP BY agent_name
                        ORDER BY count DESC
                    """)
                    by_agent = {row[0]: row[1] for row in cur.fetchall()}
                    
                    # Decisiones por sesión
                    cur.execute("""
                        SELECT session_id, COUNT(*) as count
                        FROM audit_log
                        GROUP BY session_id
                        ORDER BY count DESC
                        LIMIT 10
                    """)
                    by_session = {row[0]: row[1] for row in cur.fetchall()}
                    
                    # Confianza promedio
                    cur.execute("SELECT AVG(confidence) FROM audit_log")
                    avg_confidence = cur.fetchone()[0] or 0.0
                    
                    return {
                        "total_decisions": total,
                        "by_agent": by_agent,
                        "by_session": by_session,
                        "average_confidence": float(avg_confidence)
                    }
        except Exception as e:
            loguru_logger.error(f"Error obteniendo estadísticas: {e}")
            return {}
    
    def generate_report(
        self,
        session_id: Optional[str] = None,
        output_file: Optional[str] = None
    ) -> str:
        """
        Generar reporte de auditoría
        
        Args:
            session_id: ID de sesión (opcional, usa actual si no se especifica)
            output_file: Archivo de salida (opcional)
            
        Returns:
            Reporte en formato Markdown
        """
        session_id = session_id or self.session_id
        decisions = self.get_decisions_by_session(session_id)
        stats = self.get_statistics()
        
        report = f"""# Reporte de Auditoría

## Sesión: {session_id}
**Generado**: {datetime.now().isoformat()}

## Resumen
- **Total de Decisiones**: {len(decisions)}
- **Confianza Promedio**: {sum(d['confidence'] for d in decisions) / len(decisions) if decisions else 0:.2f}

## Decisiones

"""
        
        for i, decision in enumerate(decisions, 1):
            report += f"""### {i}. {decision['agent_name']} - {decision['action']}
**Timestamp**: {decision['timestamp']}
**Decisión**: {decision['decision']}
**Confianza**: {decision['confidence']:.2f}
**Razonamiento**: {decision['reasoning'] or 'N/A'}

"""
        
        report += f"""## Estadísticas Globales

### Decisiones por Agente
"""
        for agent, count in stats.get("by_agent", {}).items():
            report += f"- **{agent}**: {count}\n"
        
        if output_file:
            with open(output_file, "w") as f:
                f.write(report)
            loguru_logger.info(f"Reporte guardado en: {output_file}")
        
        return report


# Singleton instance
_audit_logger: Optional[AuditLogger] = None


def get_audit_logger() -> AuditLogger:
    """Obtener instancia singleton del audit logger"""
    global _audit_logger
    if _audit_logger is None:
        _audit_logger = AuditLogger()
    return _audit_logger


# CLI para consultas de auditoría
def main():
    """CLI para consultas de auditoría"""
    import sys
    
    logger = get_audit_logger()
    
    if len(sys.argv) < 2:
        print("Uso:")
        print("  python logger.py recent [limit]              # Mostrar decisiones recientes")
        print("  python logger.py by-agent <agent_name>       # Decisiones por agente")
        print("  python logger.py by-session <session_id>     # Decisiones por sesión")
        print("  python logger.py stats                       # Estadísticas")
        print("  python logger.py report [session_id]         # Generar reporte")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "recent":
        limit = int(sys.argv[2]) if len(sys.argv) > 2 else 20
        decisions = logger.get_recent_decisions(limit=limit)
        
        print(f"\n📋 Últimas {len(decisions)} decisiones:\n")
        for d in decisions:
            print(f"[{d['timestamp']}] {d['agent_name']} - {d['action']}")
            print(f"  Decisión: {d['decision']}")
            print(f"  Confianza: {d['confidence']:.2f}")
            print("-" * 50)
    
    elif command == "by-agent":
        if len(sys.argv) < 3:
            print("Uso: python logger.py by-agent <agent_name>")
            sys.exit(1)
        
        agent_name = sys.argv[2]
        decisions = logger.get_recent_decisions(agent_name=agent_name)
        
        print(f"\n📋 Decisiones de {agent_name}:\n")
        for d in decisions:
            print(f"[{d['timestamp']}] {d['action']}")
            print(f"  Decisión: {d['decision']}")
            print("-" * 50)
    
    elif command == "by-session":
        if len(sys.argv) < 3:
            print("Uso: python logger.py by-session <session_id>")
            sys.exit(1)
        
        session_id = sys.argv[2]
        decisions = logger.get_decisions_by_session(session_id)
        
        print(f"\n📋 Decisiones de sesión {session_id}:\n")
        for d in decisions:
            print(f"[{d['timestamp']}] {d['agent_name']} - {d['action']}")
            print(f"  Decisión: {d['decision']}")
            print("-" * 50)
    
    elif command == "stats":
        stats = logger.get_statistics()
        
        print("\n📊 Estadísticas de Auditoría:\n")
        print(f"Total de decisiones: {stats['total_decisions']}")
        print(f"Confianza promedio: {stats['average_confidence']:.2f}")
        print("\nDecisiones por agente:")
        for agent, count in stats['by_agent'].items():
            print(f"  {agent}: {count}")
    
    elif command == "report":
        session_id = sys.argv[2] if len(sys.argv) > 2 else None
        output_file = f"audit_report_{session_id or 'current'}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md"
        
        report = logger.generate_report(session_id=session_id, output_file=output_file)
        print(f"\n✅ Reporte generado: {output_file}")
    
    else:
        print(f"Comando desconocido: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()
