#!/bin/bash
set -e

# Script para configurar Ollama y descargar modelos recomendados

echo "🤖 Configurando Ollama..."
echo ""

# Verificar que Ollama esté corriendo
echo "📡 Verificando conexión a Ollama..."
if ! curl -s http://ollama:11434/api/tags > /dev/null 2>&1; then
    echo "❌ Error: Ollama no está disponible"
    echo "   Asegúrate de que el contenedor esté corriendo:"
    echo "   docker compose ps ollama"
    exit 1
fi

echo "✅ Ollama está disponible"
echo ""

# Función para pull de modelo
pull_model() {
    local model=$1
    local description=$2
    
    echo "📥 Descargando modelo: $model"
    echo "   $description"
    
    if curl -s -X POST http://ollama:11434/api/pull \
        -d "{\"name\": \"$model\"}" \
        --max-time 600 > /dev/null 2>&1; then
        echo "✅ $model descargado"
    else
        echo "⚠️  Error descargando $model (puede que ya esté instalado)"
    fi
    echo ""
}

# Listar modelos disponibles
echo "📋 Modelos actualmente instalados:"
curl -s http://ollama:11434/api/tags | python3 -m json.tool 2>/dev/null || echo "Ninguno"
echo ""

# Preguntar qué modelos descargar
echo "🎯 Modelos recomendados para SDD:"
echo ""
echo "1. llama3.2:latest (8B) - General purpose, rápido"
echo "2. codellama:latest (7B) - Especializado en código"
echo "3. mistral:latest (7B) - Bueno en razonamiento"
echo "4. qwen2.5-coder:latest (7B) - Excelente para código"
echo "5. deepseek-coder:latest (6.7B) - Muy bueno para código"
echo ""

read -p "¿Descargar modelo por defecto (llama3.2:latest)? [Y/n] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    pull_model "llama3.2:latest" "General purpose, rápido (8B)"
fi

read -p "¿Descargar modelo especializado en código (qwen2.5-coder:latest)? [y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    pull_model "qwen2.5-coder:latest" "Excelente para código (7B)"
fi

# Verificar modelos instalados
echo "📋 Modelos instalados después de setup:"
curl -s http://ollama:11434/api/tags | python3 -c "
import sys, json
data = json.load(sys.stdin)
models = data.get('models', [])
if models:
    for model in models:
        name = model.get('name', 'unknown')
        size = model.get('size', 0) / (1024**3)  # GB
        print(f'  - {name} ({size:.1f} GB)')
else:
    print('  (ninguno)')
" 2>/dev/null || echo "  (error listando modelos)"

echo ""
echo "✅ Setup de Ollama completado!"
echo ""
echo "💡 Para usar Ollama en tu código:"
echo "   from src.utils.ollama_client import get_llm_router"
echo "   router = get_llm_router()"
echo "   response = router.generate('Tu prompt aquí')"
echo ""
echo "💡 Para cambiar modelo por defecto:"
echo "   Edita OLLAMA_MODEL en .env"
echo ""
echo "💡 Para descargar más modelos manualmente:"
echo "   docker compose exec ollama ollama pull <modelo>"
echo ""
