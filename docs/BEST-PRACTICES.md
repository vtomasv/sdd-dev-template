# Mejores Prácticas para Desarrollo con SDD Template

Guía de mejores prácticas basadas en [12-Factor Agents](https://github.com/humanlayer/12-factor-agents) y [ACE-FCA](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md).

## 1. Gestión de Contexto

### Principio: Context is King
El contexto es fundamental para que los agentes tomen decisiones correctas.

**Mejores prácticas:**
- Cargar contexto relevante antes de cada operación
- Almacenar contexto en PostgreSQL con embeddings
- Actualizar contexto después de cambios importantes
- Usar contexto estructurado (no solo texto plano)

**Ejemplo:**
```python
from src.utils.context_manager import ContextManager

context_mgr = ContextManager()

# Cargar contexto antes de generar spec
context = context_mgr.get_relevant_context(
    query="API REST para tareas",
    limit=10
)

# Usar contexto en generación
spec = spec_agent.generate(requirements, context=context)
```

## 2. HITL en Puntos Críticos

### Principio: Human Oversight
Decisiones críticas deben ser revisadas por humanos.

**Cuándo usar HITL:**
- ✅ Especificaciones técnicas
- ✅ Planes de implementación
- ✅ Cambios en base de datos
- ✅ Deployment a producción
- ✅ Cambios de seguridad
- ❌ Cambios menores de estilo
- ❌ Documentación simple
- ❌ Tests unitarios

**Ejemplo:**
```python
from src.skills.hitl_checkpoint import HITLCheckpointSkill, CheckpointPriority

hitl = HITLCheckpointSkill()

# Checkpoint crítico antes de deployment
checkpoint_id = hitl.create_checkpoint(
    checkpoint_name="deploy-to-production",
    agent_name="deploy_agent",
    data={"version": "1.2.0", "environment": "production"},
    priority=CheckpointPriority.CRITICAL
)

status = hitl.wait_for_approval(checkpoint_id)
if status != CheckpointStatus.APPROVED:
    raise Exception("Deployment no aprobado")
```

## 3. Auditoría Completa

### Principio: Traceability
Todas las decisiones deben ser trazables.

**Qué auditar:**
- Todas las decisiones de agentes
- Cambios en código
- Aprobaciones/rechazos HITL
- Errores y excepciones
- Llamadas a APIs externas

**Ejemplo:**
```python
from src.audit.logger import get_audit_logger

audit = get_audit_logger()

# Registrar decisión
audit.log_decision(
    agent_name="spec_agent",
    action="generate_specification",
    decision="Especificación generada con 5 requisitos funcionales",
    context={
        "input_length": len(requirements),
        "output_length": len(spec),
        "requirements_count": 5
    },
    reasoning="Basado en análisis de requisitos del usuario",
    confidence=0.95
)
```

## 4. Manejo de Errores

### Principio: Fail Gracefully
Los agentes deben manejar errores de forma elegante.

**Estrategias:**
1. **Retry con backoff**: Reintentar operaciones fallidas
2. **Fallback**: Usar alternativas cuando falla el método principal
3. **Escalate to HITL**: Pedir ayuda humana cuando no se puede resolver
4. **Log everything**: Registrar todos los errores

**Ejemplo:**
```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=10)
)
def call_external_api(data):
    try:
        response = api_client.call(data)
        return response
    except APIError as e:
        audit.log_decision(
            agent_name="api_caller",
            action="api_call_failed",
            decision=f"Error: {e}",
            confidence=0.0
        )
        raise

# Si falla después de 3 intentos, escalar a HITL
try:
    result = call_external_api(data)
except Exception as e:
    hitl.create_checkpoint(
        checkpoint_name="api-call-failed",
        agent_name="api_caller",
        data={"error": str(e), "data": data},
        priority=CheckpointPriority.HIGH
    )
```

## 5. Testing de Agentes

### Principio: Test Everything
Los agentes deben ser testeados como cualquier código.

**Tipos de tests:**
- **Unit tests**: Funciones individuales
- **Integration tests**: Interacción entre agentes
- **End-to-end tests**: Workflows completos
- **HITL simulation tests**: Simular aprobaciones/rechazos

**Ejemplo:**
```python
import pytest
from src.agents.spec_agent import SpecAgent

@pytest.fixture
def spec_agent():
    return SpecAgent()

def test_generate_spec(spec_agent):
    """Test generación de especificación"""
    requirements = "Crear API REST para tareas"
    spec = spec_agent.generate(requirements)
    
    assert len(spec) > 0
    assert "API REST" in spec
    assert "Requisitos Funcionales" in spec

def test_spec_with_context(spec_agent):
    """Test generación con contexto"""
    requirements = "Agregar autenticación"
    context = {"existing_auth": "JWT"}
    
    spec = spec_agent.generate(requirements, context=context)
    assert "JWT" in spec
```

## 6. Versionado de Especificaciones

### Principio: Version Everything
Mantener historial de especificaciones y planes.

**Estrategia:**
- Guardar cada versión en BD con número de versión
- Vincular versiones con commits de código
- Permitir rollback a versiones anteriores

**Ejemplo:**
```python
# Guardar especificación con versión
spec_version = context_mgr.save_specification(
    content=spec,
    version=1,
    session_id=session_id
)

# Actualizar especificación
spec_version = context_mgr.update_specification(
    spec_id=spec_id,
    content=new_spec,
    version=2,
    changes="Agregado requisito de autenticación"
)
```

## 7. Modularidad de Agentes

### Principio: Single Responsibility
Cada agente debe tener una responsabilidad clara.

**Separación de concerns:**
- **Spec Agent**: Solo especificaciones
- **Plan Agent**: Solo planificación
- **Dev Agent**: Solo implementación
- **Review Agent**: Solo revisión

**Anti-patrón:**
```python
# ❌ Mal: Agente hace todo
class SuperAgent:
    def do_everything(self, requirements):
        spec = self.generate_spec(requirements)
        plan = self.create_plan(spec)
        code = self.implement(plan)
        self.review(code)
        self.deploy(code)
```

**Patrón correcto:**
```python
# ✅ Bien: Agentes especializados
spec = spec_agent.generate(requirements)
plan = plan_agent.create(spec)
code = dev_agent.implement(plan)
review = review_agent.review(code)
if review.approved:
    deploy_agent.deploy(code)
```

## 8. Configuración Externalizada

### Principio: Config as Environment
Configuración debe estar en variables de entorno.

**Qué externalizar:**
- API keys
- URLs de servicios
- Timeouts
- Límites de rate
- Feature flags

**Ejemplo:**
```python
import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    anthropic_api_key: str
    antigravity_api_key: str
    hitl_enabled: bool = True
    audit_enabled: bool = True
    max_retries: int = 3
    timeout_seconds: int = 30
    
    class Config:
        env_file = ".env"

settings = Settings()
```

## 9. Integración con Antigravity

### Principio: Leverage Platform
Usar capacidades de la plataforma al máximo.

**Mejores prácticas:**
- Sincronizar contexto regularmente
- Usar sugerencias de código
- Notificar decisiones importantes
- Aprovechar code review automático

**Ejemplo:**
```python
from src.utils.antigravity_client import get_antigravity_client

antigravity = get_antigravity_client()

# Sincronizar contexto después de cambios
antigravity.sync_context({
    "project": project_name,
    "files_modified": modified_files,
    "timestamp": datetime.now().isoformat()
})

# Obtener sugerencias antes de implementar
suggestions = antigravity.get_code_suggestions(
    code=partial_code,
    language="python",
    context={"feature": "authentication"}
)
```

## 10. Documentación Continua

### Principio: Document as You Go
Documentar mientras se desarrolla, no después.

**Qué documentar:**
- Decisiones de arquitectura
- Cambios importantes
- Workarounds temporales
- Deuda técnica
- Lecciones aprendidas

**Ejemplo:**
```python
# Documentar decisión en código
def authenticate_user(username: str, password: str) -> User:
    """
    Autentica usuario usando JWT.
    
    Decisión de diseño: Usamos JWT en lugar de sesiones porque:
    1. Stateless (mejor para escalabilidad)
    2. Compatible con microservicios
    3. Fácil de implementar con FastAPI
    
    Deuda técnica: Falta implementar refresh tokens.
    TODO: Agregar refresh tokens en versión 1.2
    """
    # Implementación
```

## 11. Brownfield: Respeto al Código Existente

### Principio: Understand Before Changing
En proyectos brownfield, entender antes de modificar.

**Proceso:**
1. Analizar código existente
2. Identificar patrones y convenciones
3. Respetar arquitectura existente
4. Proponer cambios incrementales
5. No refactorizar todo a la vez

**Ejemplo:**
```python
# Analizar código existente
analysis = context_mgr.analyze_codebase(repo_path)

# Identificar patrones
patterns = {
    "naming_convention": analysis.get("naming_convention"),
    "architecture": analysis.get("architecture"),
    "testing_framework": analysis.get("testing_framework")
}

# Generar código que respeta patrones
code = dev_agent.generate(
    task=task,
    context=context,
    patterns=patterns  # Usar patrones existentes
)
```

## 12. Performance y Optimización

### Principio: Measure Before Optimizing
Medir antes de optimizar.

**Métricas clave:**
- Tiempo de respuesta de agentes
- Uso de tokens de API
- Tasa de aprobación HITL
- Tiempo de desarrollo total

**Ejemplo:**
```python
import time
from functools import wraps

def measure_performance(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        duration = time.time() - start
        
        audit.log_decision(
            agent_name=func.__name__,
            action="performance_metric",
            decision=f"Completed in {duration:.2f}s",
            context={"duration": duration}
        )
        
        return result
    return wrapper

@measure_performance
def generate_spec(requirements):
    # Implementación
    pass
```

## Checklist de Calidad

Antes de considerar una tarea completada:

- [ ] Código implementado según especificación
- [ ] Tests escritos y pasando (cobertura > 80%)
- [ ] Documentación actualizada
- [ ] Checkpoints HITL aprobados
- [ ] Decisiones registradas en audit log
- [ ] Contexto sincronizado con Antigravity
- [ ] Code review completado
- [ ] Sin vulnerabilidades de seguridad
- [ ] Performance dentro de métricas
- [ ] Cambios versionados en git

## Referencias

- [12-Factor Agents](https://github.com/humanlayer/12-factor-agents)
- [ACE-FCA](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md)
- [Humanlayer Documentation](https://www.humanlayer.dev/)
- [Clean Code](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
- [The Pragmatic Programmer](https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/)
