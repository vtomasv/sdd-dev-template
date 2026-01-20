"""
Ollama Client - Cliente para modelos LLM locales con Ollama

Proporciona interfaz unificada para interactuar con modelos locales,
con fallback automático a modelos cloud si Ollama no está disponible.
"""
import os
import requests
from typing import Optional, Dict, Any, List
from loguru import logger


class OllamaClient:
    """Cliente para interactuar con Ollama (modelos LLM locales)"""
    
    def __init__(
        self,
        base_url: Optional[str] = None,
        model: Optional[str] = None,
        timeout: int = 120
    ):
        """
        Inicializar cliente Ollama
        
        Args:
            base_url: URL base de Ollama (default: env OLLAMA_URL)
            model: Modelo a usar (default: env OLLAMA_MODEL)
            timeout: Timeout en segundos (default: 120)
        """
        self.base_url = base_url or os.getenv("OLLAMA_URL", "http://ollama:11434")
        self.model = model or os.getenv("OLLAMA_MODEL", "llama3.2:latest")
        self.timeout = timeout
        self.enabled = os.getenv("OLLAMA_ENABLED", "true").lower() == "true"
        
        logger.info(f"OllamaClient initialized: {self.base_url}, model: {self.model}")
    
    def is_available(self) -> bool:
        """
        Verificar si Ollama está disponible
        
        Returns:
            bool: True si Ollama responde, False si no
        """
        if not self.enabled:
            logger.debug("Ollama disabled via OLLAMA_ENABLED=false")
            return False
        
        try:
            response = requests.get(
                f"{self.base_url}/api/tags",
                timeout=5
            )
            return response.status_code == 200
        except Exception as e:
            logger.warning(f"Ollama not available: {e}")
            return False
    
    def list_models(self) -> List[Dict[str, Any]]:
        """
        Listar modelos disponibles en Ollama
        
        Returns:
            List[Dict]: Lista de modelos con metadata
        """
        try:
            response = requests.get(
                f"{self.base_url}/api/tags",
                timeout=10
            )
            response.raise_for_status()
            data = response.json()
            return data.get("models", [])
        except Exception as e:
            logger.error(f"Error listing Ollama models: {e}")
            return []
    
    def pull_model(self, model: Optional[str] = None) -> bool:
        """
        Descargar modelo si no existe
        
        Args:
            model: Nombre del modelo (default: self.model)
        
        Returns:
            bool: True si descarga exitosa, False si falla
        """
        model = model or self.model
        
        try:
            logger.info(f"Pulling Ollama model: {model}")
            response = requests.post(
                f"{self.base_url}/api/pull",
                json={"name": model},
                timeout=600,  # 10 minutos para descarga
                stream=True
            )
            
            # Procesar respuesta streaming
            for line in response.iter_lines():
                if line:
                    data = line.decode('utf-8')
                    logger.debug(f"Pull progress: {data}")
            
            return True
        except Exception as e:
            logger.error(f"Error pulling model {model}: {e}")
            return False
    
    def generate(
        self,
        prompt: str,
        model: Optional[str] = None,
        system: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 2000,
        stream: bool = False
    ) -> str:
        """
        Generar texto con Ollama
        
        Args:
            prompt: Prompt del usuario
            model: Modelo a usar (default: self.model)
            system: System prompt opcional
            temperature: Temperatura (0.0-1.0)
            max_tokens: Máximo de tokens a generar
            stream: Si True, retorna generator; si False, retorna string completo
        
        Returns:
            str: Texto generado
        """
        model = model or self.model
        
        payload = {
            "model": model,
            "prompt": prompt,
            "stream": stream,
            "options": {
                "temperature": temperature,
                "num_predict": max_tokens
            }
        }
        
        if system:
            payload["system"] = system
        
        try:
            response = requests.post(
                f"{self.base_url}/api/generate",
                json=payload,
                timeout=self.timeout,
                stream=stream
            )
            response.raise_for_status()
            
            if stream:
                # Retornar generator para streaming
                def stream_generator():
                    for line in response.iter_lines():
                        if line:
                            data = line.decode('utf-8')
                            import json
                            chunk = json.loads(data)
                            if "response" in chunk:
                                yield chunk["response"]
                return stream_generator()
            else:
                # Retornar texto completo
                full_response = ""
                for line in response.iter_lines():
                    if line:
                        data = line.decode('utf-8')
                        import json
                        chunk = json.loads(data)
                        if "response" in chunk:
                            full_response += chunk["response"]
                
                return full_response
        
        except Exception as e:
            logger.error(f"Error generating with Ollama: {e}")
            raise
    
    def chat(
        self,
        messages: List[Dict[str, str]],
        model: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 2000
    ) -> str:
        """
        Chat con Ollama (formato OpenAI-compatible)
        
        Args:
            messages: Lista de mensajes [{"role": "user", "content": "..."}]
            model: Modelo a usar (default: self.model)
            temperature: Temperatura (0.0-1.0)
            max_tokens: Máximo de tokens a generar
        
        Returns:
            str: Respuesta del modelo
        """
        model = model or self.model
        
        payload = {
            "model": model,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": temperature,
                "num_predict": max_tokens
            }
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/api/chat",
                json=payload,
                timeout=self.timeout
            )
            response.raise_for_status()
            data = response.json()
            
            return data.get("message", {}).get("content", "")
        
        except Exception as e:
            logger.error(f"Error chatting with Ollama: {e}")
            raise


class LLMRouter:
    """
    Router que decide entre Ollama (local) y modelos cloud
    
    Prioriza Ollama si está disponible, fallback a cloud si no.
    """
    
    def __init__(self):
        """Inicializar router con Ollama y clientes cloud"""
        self.ollama = OllamaClient()
        self.use_ollama = self.ollama.is_available()
        
        if self.use_ollama:
            logger.info("LLMRouter: Using Ollama (local)")
        else:
            logger.info("LLMRouter: Ollama unavailable, will use cloud models")
    
    def generate(
        self,
        prompt: str,
        system: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 2000,
        prefer_local: bool = True
    ) -> str:
        """
        Generar texto con router automático
        
        Args:
            prompt: Prompt del usuario
            system: System prompt opcional
            temperature: Temperatura
            max_tokens: Máximo de tokens
            prefer_local: Si True, intenta Ollama primero
        
        Returns:
            str: Texto generado
        """
        if prefer_local and self.use_ollama:
            try:
                return self.ollama.generate(
                    prompt=prompt,
                    system=system,
                    temperature=temperature,
                    max_tokens=max_tokens
                )
            except Exception as e:
                logger.warning(f"Ollama failed, falling back to cloud: {e}")
        
        # Fallback a cloud (Anthropic, OpenAI, etc.)
        return self._generate_cloud(prompt, system, temperature, max_tokens)
    
    def _generate_cloud(
        self,
        prompt: str,
        system: Optional[str],
        temperature: float,
        max_tokens: int
    ) -> str:
        """
        Generar con modelos cloud (fallback)
        
        Prioridad: Anthropic > OpenAI > Gemini
        """
        # Intentar Anthropic
        anthropic_key = os.getenv("ANTHROPIC_API_KEY")
        if anthropic_key and anthropic_key != "sk-ant-REPLACE_ME":
            try:
                import anthropic
                client = anthropic.Anthropic(api_key=anthropic_key)
                
                messages = [{"role": "user", "content": prompt}]
                
                response = client.messages.create(
                    model="claude-3-5-sonnet-20241022",
                    max_tokens=max_tokens,
                    temperature=temperature,
                    system=system or "",
                    messages=messages
                )
                
                return response.content[0].text
            except Exception as e:
                logger.warning(f"Anthropic failed: {e}")
        
        # Intentar OpenAI
        openai_key = os.getenv("OPENAI_API_KEY")
        if openai_key and openai_key != "sk-REPLACE_ME":
            try:
                from openai import OpenAI
                client = OpenAI(api_key=openai_key)
                
                messages = []
                if system:
                    messages.append({"role": "system", "content": system})
                messages.append({"role": "user", "content": prompt})
                
                response = client.chat.completions.create(
                    model="gpt-4",
                    messages=messages,
                    temperature=temperature,
                    max_tokens=max_tokens
                )
                
                return response.choices[0].message.content
            except Exception as e:
                logger.warning(f"OpenAI failed: {e}")
        
        raise Exception("No LLM provider available (Ollama, Anthropic, OpenAI all failed)")


# Singleton global
_llm_router: Optional[LLMRouter] = None


def get_llm_router() -> LLMRouter:
    """
    Obtener instancia global de LLMRouter
    
    Returns:
        LLMRouter: Instancia singleton
    """
    global _llm_router
    if _llm_router is None:
        _llm_router = LLMRouter()
    return _llm_router


# Ejemplo de uso
if __name__ == "__main__":
    # Test básico
    router = get_llm_router()
    
    response = router.generate(
        prompt="Explica qué es SDD en 2 líneas",
        system="Eres un experto en metodologías de desarrollo de software.",
        temperature=0.7,
        max_tokens=100
    )
    
    print(f"Response: {response}")
