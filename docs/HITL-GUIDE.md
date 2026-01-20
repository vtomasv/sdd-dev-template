# HITL (Human-in-the-Loop) Guide

Guía completa para usar checkpoints de aprobación manual en el desarrollo con agentes de IA.

## Introducción

**HITL (Human-in-the-Loop)** es una práctica fundamental para garantizar que las decisiones críticas de los agentes de IA sean revisadas y aprobadas por humanos antes de proceder. Esto es especialmente importante en:

- Decisiones de arquitectura
- Cambios en código crítico
- Modificaciones en base de datos
- Deployment a producción
- Cambios que afectan seguridad o compliance

Este template implementa HITL siguiendo las mejores prácticas de [Humanlayer](https://www.humanlayer.dev/).

## Conceptos Clave

### Checkpoint
Un **checkpoint** es un punto de pausa en el workflow donde se requiere aprobación humana antes de continuar.

### Estados de Checkpoint
- **Pending**: Esperando revisión
- **Approved**: Aprobado, puede continuar
- **Rejected**: Rechazado, debe corregirse
- **Timeout**: Expiró sin respuesta

### Prioridades
- **Low**: Sugerencias opcionales
- **Medium**: Cambios importantes pero no críticos
- **High**: Cambios críticos que requieren revisión
- **Critical**: Cambios que afectan seguridad o producción

## Checkpoints Predefinidos

### 1. Spec Approval
**Cuándo**: Después de generar especificación técnica  
**Agente**: Spec Agent  
**Qué revisar**:
- Requisitos funcionales completos
- Requisitos no funcionales adecuados
- Arquitectura propuesta viable
- Estimaciones realistas

**Ejemplo**:
```bash
# El Spec Agent crea automáticamente este checkpoint
# Revisar con:
python src/skills/hitl_checkpoint.py list

# Aprobar:
python src/skills/hitl_checkpoint.py approve <id> <tu-nombre>
```

### 2. Plan Approval
**Cuándo**: Después de generar plan de implementación  
**Agente**: Plan Agent  
**Qué revisar**:
- Tareas bien definidas
- Dependencias correctas
- Estimaciones razonables
- Priorización adecuada

### 3. Code Review
**Cuándo**: Después de implementar código crítico  
**Agente**: Dev Agent  
**Qué revisar**:
- Código cumple especificación
- Tests adecuados
- Sin vulnerabilidades
- Performance aceptable

### 4. Database Migration
**Cuándo**: Antes de ejecutar migraciones de BD  
**Agente**: Dev Agent  
**Qué revisar**:
- Migración reversible
- Backup realizado
- Datos no se pierden
- Performance no afectada

### 5. Deployment
**Cuándo**: Antes de deployment a producción  
**Agente**: Review Agent  
**Qué revisar**:
- Todos los tests pasan
- Code review completado
- Documentación actualizada
- Rollback plan definido

## Uso Básico

### Listar Checkpoints Pendientes

```bash
python src/skills/hitl_checkpoint.py list
```

**Salida**:
```
📋 3 checkpoint(s) pendiente(s):

ID: 1
Nombre: spec-approval-api-rest
Agente: spec_agent
Creado: 2024-01-15T10:30:00
Datos: {'spec_file': '.specify/specs/api-rest.md', 'priority': 'high'}
--------------------------------------------------
ID: 2
Nombre: plan-approval-api-rest
Agente: plan_agent
Creado: 2024-01-15T11:00:00
Datos: {'plan_file': '.specify/speckit.tasks', 'priority': 'medium'}
--------------------------------------------------
```

### Aprobar Checkpoint

```bash
python src/skills/hitl_checkpoint.py approve <checkpoint-id> <tu-nombre>
```

**Ejemplo**:
```bash
python src/skills/hitl_checkpoint.py approve 1 juan.perez
# ✅ Checkpoint 1 aprobado por juan.perez
```

### Rechazar Checkpoint

```bash
python src/skills/hitl_checkpoint.py reject <checkpoint-id> <tu-nombre> "<comentarios>"
```

**Ejemplo**:
```bash
python src/skills/hitl_checkpoint.py reject 2 juan.perez "Falta considerar casos edge en el plan"
# ❌ Checkpoint 2 rechazado por juan.perez
```

## Uso Avanzado

### Crear Checkpoint Personalizado

```python
from src.skills.hitl_checkpoint import HITLCheckpointSkill, CheckpointPriority

skill = HITLCheckpointSkill()

# Crear checkpoint
checkpoint_id = skill.create_checkpoint(
    checkpoint_name="custom-review-feature-x",
    agent_name="dev_agent",
    data={
        "feature": "feature-x",
        "files_modified": ["src/api.py", "src/models.py"],
        "lines_changed": 150
    },
    priority=CheckpointPriority.HIGH,
    context={
        "reason": "Cambios en lógica crítica de negocio",
        "reviewer_suggested": "tech-lead"
    },
    timeout_seconds=3600  # 1 hora
)

print(f"Checkpoint creado: {checkpoint_id}")
```

### Esperar Aprobación en Código

```python
from src.skills.hitl_checkpoint import HITLCheckpointSkill, CheckpointStatus

skill = HITLCheckpointSkill()

# Crear checkpoint
checkpoint_id = skill.create_checkpoint(
    checkpoint_name="deploy-to-production",
    agent_name="deploy_agent",
    data={"environment": "production", "version": "1.2.0"},
    priority=CheckpointPriority.CRITICAL
)

# Esperar aprobación
status = skill.wait_for_approval(checkpoint_id, timeout_seconds=1800)

if status == CheckpointStatus.APPROVED:
    print("✅ Deployment aprobado, procediendo...")
    # Continuar con deployment
elif status == CheckpointStatus.REJECTED:
    print("❌ Deployment rechazado, abortando...")
    # Abortar deployment
else:
    print("⏱️ Timeout, escalando a supervisor...")
    # Escalar
```

### Integración con Agentes

Los agentes pueden crear checkpoints automáticamente:

```python
from src.audit.logger import get_audit_logger
from src.skills.hitl_checkpoint import HITLCheckpointSkill, CheckpointPriority

class SpecAgent:
    def __init__(self):
        self.audit_logger = get_audit_logger()
        self.hitl_skill = HITLCheckpointSkill()
    
    def generate_spec(self, requirements: str) -> str:
        # Generar especificación
        spec = self._generate_spec_content(requirements)
        
        # Registrar en auditoría
        self.audit_logger.log_decision(
            agent_name="spec_agent",
            action="generate_spec",
            decision=f"Especificación generada: {len(spec)} caracteres",
            reasoning="Basado en requisitos del usuario"
        )
        
        # Crear checkpoint HITL
        checkpoint_id = self.hitl_skill.create_checkpoint(
            checkpoint_name=f"spec-approval-{datetime.now().strftime('%Y%m%d-%H%M%S')}",
            agent_name="spec_agent",
            data={
                "spec_preview": spec[:500],
                "total_length": len(spec),
                "requirements_count": requirements.count('\n')
            },
            priority=CheckpointPriority.HIGH
        )
        
        # Esperar aprobación
        status = self.hitl_skill.wait_for_approval(checkpoint_id)
        
        if status == CheckpointStatus.APPROVED:
            return spec
        else:
            raise Exception("Especificación rechazada")
```

## Notificaciones

### Configurar Slack

```bash
# En .env
HITL_SLACK_WEBHOOK=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

Las notificaciones se enviarán automáticamente a Slack cuando se cree un checkpoint.

### Configurar Email (futuro)

```bash
# En .env
HITL_EMAIL_NOTIFICATIONS=true
HITL_EMAIL_RECIPIENTS=team@example.com,lead@example.com
```

## Mejores Prácticas

### 1. Definir Criterios Claros

Cada checkpoint debe tener criterios claros de aprobación:

```python
checkpoint_id = skill.create_checkpoint(
    checkpoint_name="code-review-auth-module",
    agent_name="dev_agent",
    data={
        "module": "authentication",
        "criteria": [
            "Tests de seguridad pasan",
            "Cobertura > 90%",
            "Sin vulnerabilidades conocidas",
            "Performance < 100ms"
        ]
    },
    priority=CheckpointPriority.CRITICAL
)
```

### 2. Priorizar Correctamente

- **Critical**: Solo para cambios que afectan producción, seguridad, o datos
- **High**: Cambios arquitectónicos o en lógica de negocio
- **Medium**: Features nuevas o refactoring significativo
- **Low**: Mejoras menores o documentación

### 3. Documentar Decisiones

Siempre incluir comentarios al aprobar o rechazar:

```bash
# Bueno
python src/skills/hitl_checkpoint.py approve 1 juan "Tests verificados, arquitectura sólida"

# Mejor
python src/skills/hitl_checkpoint.py reject 2 juan "Falta manejo de error en línea 45, considerar caso cuando usuario no existe"
```

### 4. Timeouts Apropiados

- **Critical**: 30-60 minutos
- **High**: 1-2 horas
- **Medium**: 4-8 horas
- **Low**: 24 horas

### 5. Revisar Regularmente

```bash
# Agregar a crontab o script diario
python src/skills/hitl_checkpoint.py list | mail -s "Checkpoints Pendientes" team@example.com
```

## Workflows con HITL

### Workflow Greenfield

```
1. Usuario define requisitos
2. Spec Agent genera especificación
3. [HITL] Aprobar especificación ⏸️
4. Plan Agent genera plan
5. [HITL] Aprobar plan ⏸️
6. Dev Agent implementa fase 1
7. [HITL] Revisar código fase 1 ⏸️
8. Dev Agent implementa fase 2
9. [HITL] Revisar código fase 2 ⏸️
10. Review Agent valida todo
11. [HITL] Aprobar deployment ⏸️
12. Deploy a producción
```

### Workflow Brownfield

```
1. Analizar código existente
2. [HITL] Validar análisis ⏸️
3. Spec Agent propone mejoras
4. [HITL] Aprobar propuesta ⏸️
5. Plan Agent genera plan de migración
6. [HITL] Aprobar plan de migración ⏸️
7. Dev Agent implementa cambios
8. [HITL] Revisar compatibilidad ⏸️
9. Testing en staging
10. [HITL] Aprobar deployment ⏸️
11. Deploy a producción
```

## Integración con CI/CD

### GitHub Actions

```yaml
# .github/workflows/hitl-check.yml
name: HITL Check

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  hitl-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Check pending HITL checkpoints
        run: |
          docker compose up -d postgres
          docker compose exec -T dev python src/skills/hitl_checkpoint.py list
          
      - name: Block if critical checkpoints pending
        run: |
          PENDING=$(docker compose exec -T dev python -c "
          from src.skills.hitl_checkpoint import HITLCheckpointSkill
          skill = HITLCheckpointSkill()
          checkpoints = skill.get_pending_checkpoints()
          critical = [c for c in checkpoints if c['data'].get('priority') == 'critical']
          print(len(critical))
          ")
          
          if [ "$PENDING" -gt 0 ]; then
            echo "❌ Hay $PENDING checkpoint(s) crítico(s) pendiente(s)"
            exit 1
          fi
```

## Métricas y Reporting

### Ver Estadísticas de Checkpoints

```sql
-- Conectar a PostgreSQL
docker compose exec postgres psql -U sdd -d sdd

-- Checkpoints por estado
SELECT status, COUNT(*) 
FROM hitl_checkpoints 
GROUP BY status;

-- Tiempo promedio de aprobación
SELECT AVG(EXTRACT(EPOCH FROM (reviewed_at - created_at))) as avg_seconds
FROM hitl_checkpoints
WHERE status = 'approved';

-- Checkpoints por agente
SELECT agent_name, COUNT(*) 
FROM hitl_checkpoints 
GROUP BY agent_name
ORDER BY COUNT(*) DESC;
```

### Generar Reporte

```bash
python - <<'PY'
from src.skills.hitl_checkpoint import HITLCheckpointSkill
import psycopg
import os

skill = HITLCheckpointSkill()

with psycopg.connect(os.getenv("DATABASE_URL")) as conn:
    with conn.cursor() as cur:
        cur.execute("""
            SELECT 
                status,
                COUNT(*) as count,
                AVG(EXTRACT(EPOCH FROM (reviewed_at - created_at))) as avg_time
            FROM hitl_checkpoints
            WHERE reviewed_at IS NOT NULL
            GROUP BY status
        """)
        
        print("\n📊 Reporte de Checkpoints HITL\n")
        for row in cur.fetchall():
            status, count, avg_time = row
            print(f"{status}: {count} checkpoints")
            if avg_time:
                print(f"  Tiempo promedio: {avg_time/60:.1f} minutos")
PY
```

## Troubleshooting

### Checkpoint no aparece en lista

```bash
# Verificar que HITL esté habilitado
echo $HITL_ENABLED  # Debe ser "true"

# Verificar conexión a BD
python -c "from src.skills.hitl_checkpoint import HITLCheckpointSkill; skill = HITLCheckpointSkill(); print(skill.get_pending_checkpoints())"
```

### Notificaciones no llegan

```bash
# Verificar webhook de Slack
echo $HITL_SLACK_WEBHOOK

# Probar manualmente
curl -X POST $HITL_SLACK_WEBHOOK -H 'Content-Type: application/json' -d '{"text":"Test"}'
```

## Referencias

- [Humanlayer Documentation](https://www.humanlayer.dev/)
- [12-Factor Agents - Human Oversight](https://github.com/humanlayer/12-factor-agents#factor-8-human-oversight)
- [ACE-FCA - Approval Workflows](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md#approval-workflows)
