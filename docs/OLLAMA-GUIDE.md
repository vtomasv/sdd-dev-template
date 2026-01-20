# Guía de Ollama - Modelos LLM Locales

Esta guía explica cómo usar **Ollama** para ejecutar modelos de lenguaje (LLM) localmente en el template SDD, con privacidad completa y sin costos de API.

## ¿Qué es Ollama?

**Ollama** es una plataforma para ejecutar modelos de lenguaje grandes (LLM) localmente en tu infraestructura, sin enviar datos a servicios cloud.

### Ventajas de Ollama

- ✅ **Privacidad Total**: Datos sensibles nunca salen de tu servidor
- ✅ **Sin Costos de API**: No hay límites ni cargos por uso
- ✅ **Baja Latencia**: Procesamiento local más rápido
- ✅ **Funciona Offline**: No requiere conexión a internet
- ✅ **Control Completo**: Elige modelos y configuración

### Desventajas

- ⚠️ **Requiere GPU**: Mejor rendimiento con GPU (opcional)
- ⚠️ **Modelos más pequeños**: 7B-13B vs 70B+ en cloud
- ⚠️ **Almacenamiento**: Modelos ocupan 4-8 GB cada uno

## Instalación

### Ya está incluido en el template

Ollama ya está configurado en `docker-compose.yml`:

```yaml
ollama:
  image: ollama/ollama:latest
  container_name: sdd-ollama
  ports:
    - "11434:11434"
  volumes:
    - ./.data/ollama:/root/.ollama
  environment:
    - OLLAMA_HOST=0.0.0.0
```

### Iniciar Ollama

```bash
# Levantar todos los servicios (incluye Ollama)
docker compose up -d

# Verificar que Ollama esté corriendo
docker compose ps ollama

# Ver logs de Ollama
docker compose logs -f ollama
```

### Verificar Instalación

```bash
# Desde el host
curl http://localhost:11434/api/tags

# Desde el dev container
curl http://ollama:11434/api/tags
```

## Setup Inicial

### Script Automático (Recomendado)

El template incluye un script para configurar Ollama:

```bash
# Entrar al dev container
docker compose exec dev bash

# Ejecutar script de setup
bash scripts/05_setup-ollama.sh
```

El script:
1. Verifica conexión a Ollama
2. Lista modelos instalados
3. Ofrece descargar modelos recomendados
4. Valida instalación

### Setup Manual

```bash
# Descargar modelo por defecto
docker compose exec ollama ollama pull llama3.2:latest

# Descargar modelo especializado en código
docker compose exec ollama ollama pull qwen2.5-coder:latest

# Listar modelos instalados
docker compose exec ollama ollama list
```

## Modelos Recomendados

### Para Uso General

| Modelo | Tamaño | RAM | Velocidad | Uso |
|--------|--------|-----|-----------|-----|
| `llama3.2:latest` | 8B | 8 GB | ⚡⚡⚡ | General, conversación |
| `mistral:latest` | 7B | 8 GB | ⚡⚡ | Razonamiento, análisis |
| `gemma2:latest` | 9B | 10 GB | ⚡⚡ | General, eficiente |

### Para Código

| Modelo | Tamaño | RAM | Velocidad | Uso |
|--------|--------|-----|-----------|-----|
| `qwen2.5-coder:latest` | 7B | 8 GB | ⚡⚡⚡ | **Recomendado** - Excelente para código |
| `codellama:latest` | 7B | 8 GB | ⚡⚡ | Code generation, debugging |
| `deepseek-coder:latest` | 6.7B | 7 GB | ⚡⚡⚡ | Muy bueno para código |
| `starcoder2:latest` | 7B | 8 GB | ⚡⚡ | Code completion |

### Para Tareas Específicas

| Modelo | Tamaño | RAM | Uso |
|--------|--------|-----|-----|
| `llama3.2-vision:latest` | 11B | 12 GB | Análisis de imágenes |
| `nomic-embed-text:latest` | 137M | 1 GB | Embeddings para RAG |
| `all-minilm:latest` | 22M | 500 MB | Embeddings ligeros |

## Uso en Python

### Cliente Básico

```python
from src.utils.ollama_client import OllamaClient

# Inicializar cliente
client = OllamaClient(
    base_url="http://ollama:11434",
    model="qwen2.5-coder:latest"
)

# Verificar disponibilidad
if client.is_available():
    print("✅ Ollama disponible")
else:
    print("❌ Ollama no disponible")

# Generar texto
response = client.generate(
    prompt="Explica qué es un API REST en 3 líneas",
    system="Eres un experto en desarrollo de software.",
    temperature=0.7,
    max_tokens=200
)

print(response)
```

### Router Automático (Local + Cloud)

```python
from src.utils.ollama_client import get_llm_router

# Obtener router (singleton)
router = get_llm_router()

# Generar con fallback automático
# Intenta Ollama primero, si falla usa cloud
response = router.generate(
    prompt="Genera una función Python para calcular Fibonacci",
    system="Eres un experto en Python.",
    temperature=0.3,
    max_tokens=500,
    prefer_local=True  # Prioriza Ollama
)

print(response)
```

### Chat Multi-Turn

```python
from src.utils.ollama_client import OllamaClient

client = OllamaClient(model="qwen2.5-coder:latest")

messages = [
    {"role": "user", "content": "¿Qué es FastAPI?"},
    {"role": "assistant", "content": "FastAPI es un framework web moderno..."},
    {"role": "user", "content": "Dame un ejemplo de endpoint"}
]

response = client.chat(
    messages=messages,
    temperature=0.5,
    max_tokens=1000
)

print(response)
```

### Streaming

```python
from src.utils.ollama_client import OllamaClient

client = OllamaClient()

# Generar con streaming
stream = client.generate(
    prompt="Escribe un poema sobre IA",
    stream=True
)

# Procesar chunks en tiempo real
for chunk in stream:
    print(chunk, end='', flush=True)
```

## Uso en Workflows

### Nodo Skill con Ollama

En `.claude/workflows/*.json`:

```json
{
  "type": "Skill",
  "data": {
    "label": "Process with Ollama",
    "skillName": "ollama_generate",
    "parameters": {
      "prompt": "{{user_input}}",
      "model": "qwen2.5-coder:latest",
      "temperature": 0.3,
      "max_tokens": 2000
    }
  }
}
```

### Workflow con Privacidad

Ver ejemplo completo en `.claude/workflows/local-llm-workflow.json`

## Configuración

### Variables de Entorno

En `.env`:

```bash
# URL de Ollama
OLLAMA_URL=http://ollama:11434

# Modelo por defecto
OLLAMA_MODEL=qwen2.5-coder:latest

# Habilitar Ollama
OLLAMA_ENABLED=true
```

### Cambiar Modelo por Defecto

```bash
# Opción 1: Editar .env
echo "OLLAMA_MODEL=llama3.2:latest" >> .env

# Opción 2: Variable de entorno
export OLLAMA_MODEL=mistral:latest

# Opción 3: En código Python
client = OllamaClient(model="codellama:latest")
```

## Gestión de Modelos

### Listar Modelos

```bash
# Listar modelos instalados
docker compose exec ollama ollama list

# Desde Python
from src.utils.ollama_client import OllamaClient
client = OllamaClient()
models = client.list_models()
for model in models:
    print(f"- {model['name']} ({model['size']/1e9:.1f} GB)")
```

### Descargar Modelos

```bash
# Descargar modelo específico
docker compose exec ollama ollama pull qwen2.5-coder:latest

# Descargar múltiples modelos
docker compose exec ollama ollama pull llama3.2:latest
docker compose exec ollama ollama pull mistral:latest
docker compose exec ollama ollama pull codellama:latest

# Desde Python
from src.utils.ollama_client import OllamaClient
client = OllamaClient()
success = client.pull_model("qwen2.5-coder:latest")
```

### Eliminar Modelos

```bash
# Eliminar modelo para liberar espacio
docker compose exec ollama ollama rm llama3.2:latest

# Ver espacio usado
du -sh ./.data/ollama/
```

## Optimización

### Rendimiento con GPU

Si tienes GPU NVIDIA:

```yaml
# docker-compose.yml
ollama:
  image: ollama/ollama:latest
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: 1
            capabilities: [gpu]
```

Luego:

```bash
# Reiniciar con GPU
docker compose down
docker compose up -d
```

### Ajustar Parámetros

```python
# Más creativo (temperatura alta)
response = client.generate(
    prompt="Genera ideas innovadoras",
    temperature=0.9,  # 0.0-1.0
    max_tokens=1000
)

# Más determinístico (temperatura baja)
response = client.generate(
    prompt="Genera código Python",
    temperature=0.1,  # Más preciso
    max_tokens=500
)
```

### Caché de Contexto

Ollama cachea automáticamente el contexto para requests similares:

```python
# Primera request: lenta (carga modelo)
response1 = client.generate("Explica FastAPI")

# Segunda request: rápida (usa caché)
response2 = client.generate("Dame un ejemplo de FastAPI")
```

## Casos de Uso

### 1. Procesamiento de Datos Sensibles

```python
from src.utils.ollama_client import OllamaClient

client = OllamaClient(model="qwen2.5-coder:latest")

# Datos sensibles (PII, secretos, etc.)
sensitive_data = """
Usuario: Juan Pérez
Email: juan@empresa.com
Tarjeta: 4532-1234-5678-9012
"""

# Procesar localmente (no sale del servidor)
response = client.generate(
    prompt=f"Analiza estos datos y genera un resumen sin incluir información sensible:\n\n{sensitive_data}",
    system="Eres un experto en privacidad de datos.",
    temperature=0.3
)

print(response)
```

### 2. Generación de Código

```python
from src.utils.ollama_client import OllamaClient

client = OllamaClient(model="qwen2.5-coder:latest")

response = client.generate(
    prompt="""
Genera una función Python que:
1. Lea un archivo CSV
2. Filtre filas donde 'status' == 'active'
3. Calcule la suma de la columna 'amount'
4. Retorne el resultado
""",
    system="Eres un experto en Python. Genera código limpio y con type hints.",
    temperature=0.2,
    max_tokens=500
)

print(response)
```

### 3. Code Review Local

```python
from src.utils.ollama_client import OllamaClient

client = OllamaClient(model="qwen2.5-coder:latest")

code = """
def process_data(data):
    result = []
    for item in data:
        if item['status'] == 'active':
            result.append(item)
    return result
"""

response = client.generate(
    prompt=f"Revisa este código y sugiere mejoras:\n\n```python\n{code}\n```",
    system="Eres un senior Python developer. Enfócate en: performance, legibilidad, type safety.",
    temperature=0.3
)

print(response)
```

### 4. Análisis de Logs

```python
from src.utils.ollama_client import OllamaClient

client = OllamaClient(model="mistral:latest")

logs = """
2026-01-19 10:15:23 ERROR Database connection failed
2026-01-19 10:15:24 ERROR Retry attempt 1/3
2026-01-19 10:15:25 ERROR Retry attempt 2/3
2026-01-19 10:15:26 ERROR Retry attempt 3/3
2026-01-19 10:15:27 CRITICAL Service unavailable
"""

response = client.generate(
    prompt=f"Analiza estos logs y sugiere soluciones:\n\n{logs}",
    system="Eres un experto en troubleshooting de sistemas.",
    temperature=0.4
)

print(response)
```

## Troubleshooting

### Ollama no inicia

**Problema**: `docker compose up -d` falla para Ollama

**Solución**:
```bash
# Ver logs detallados
docker compose logs ollama

# Verificar puerto disponible
netstat -tulpn | grep 11434

# Reiniciar servicio
docker compose restart ollama
```

### Modelo no se descarga

**Problema**: `ollama pull` timeout o falla

**Solución**:
```bash
# Verificar espacio en disco
df -h

# Verificar conexión a internet
docker compose exec ollama ping -c 3 ollama.ai

# Descargar con más timeout
docker compose exec ollama ollama pull llama3.2:latest --timeout 600
```

### Respuestas lentas

**Problema**: Ollama tarda mucho en responder

**Solución**:
1. Usa modelos más pequeños (7B en vez de 13B)
2. Reduce `max_tokens`
3. Habilita GPU si disponible
4. Aumenta RAM del contenedor

### Out of Memory

**Problema**: Ollama crash por falta de memoria

**Solución**:
```bash
# Ver uso de memoria
docker stats sdd-ollama

# Aumentar límite de memoria en docker-compose.yml
ollama:
  deploy:
    resources:
      limits:
        memory: 16G
```

## Comparación: Ollama vs Cloud

| Aspecto | Ollama (Local) | Cloud (Anthropic/OpenAI) |
|---------|----------------|--------------------------|
| **Privacidad** | ✅ Total | ⚠️ Datos enviados a terceros |
| **Costo** | ✅ Gratis | 💰 $0.01-$0.10 por 1K tokens |
| **Latencia** | ⚡ 50-200ms | 🐌 200-1000ms |
| **Calidad** | 🟡 Buena (7B-13B) | ✅ Excelente (70B+) |
| **Offline** | ✅ Funciona | ❌ Requiere internet |
| **Escalabilidad** | ⚠️ Limitada por hardware | ✅ Ilimitada |
| **Mantenimiento** | ⚠️ Requiere gestión | ✅ Cero mantenimiento |

### Cuándo usar Ollama

✅ Datos sensibles (PII, secretos, código propietario)  
✅ Desarrollo local sin internet  
✅ Prototipado rápido sin costos  
✅ Tareas simples (code completion, análisis)  
✅ Volumen alto de requests

### Cuándo usar Cloud

✅ Tareas complejas que requieren razonamiento avanzado  
✅ Generación de contenido creativo de alta calidad  
✅ Análisis de contextos muy largos (>8K tokens)  
✅ Producción con SLA garantizado  
✅ Sin recursos de hardware para Ollama

## Recursos Adicionales

- **Sitio oficial**: https://ollama.ai
- **Repositorio**: https://github.com/ollama/ollama
- **Modelos disponibles**: https://ollama.ai/library
- **Documentación API**: https://github.com/ollama/ollama/blob/main/docs/api.md

## Próximos Pasos

1. ✅ Ejecuta `bash scripts/05_setup-ollama.sh`
2. ✅ Descarga modelos recomendados
3. ✅ Prueba el cliente Python
4. ✅ Crea un workflow con Ollama
5. ✅ Integra en tus agentes

¡Disfruta de LLMs locales con privacidad total! 🤖🔒
