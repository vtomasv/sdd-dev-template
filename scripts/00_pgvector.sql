-- Inicialización de pgvector y tablas de auditoría

-- Habilitar extensión pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- Tabla de contexto con embeddings
CREATE TABLE IF NOT EXISTS context_embeddings (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    embedding vector(1536),
    metadata JSONB,
    source VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índice para búsqueda de similitud
CREATE INDEX IF NOT EXISTS context_embeddings_embedding_idx 
ON context_embeddings USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Tabla de auditoría de decisiones de IA
CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    agent_name VARCHAR(100) NOT NULL,
    action VARCHAR(255) NOT NULL,
    decision TEXT NOT NULL,
    context JSONB,
    reasoning TEXT,
    confidence FLOAT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id VARCHAR(100),
    user_id VARCHAR(100)
);

-- Índices para auditoría
CREATE INDEX IF NOT EXISTS audit_log_agent_idx ON audit_log(agent_name);
CREATE INDEX IF NOT EXISTS audit_log_timestamp_idx ON audit_log(timestamp DESC);
CREATE INDEX IF NOT EXISTS audit_log_session_idx ON audit_log(session_id);

-- Tabla de checkpoints HITL
CREATE TABLE IF NOT EXISTS hitl_checkpoints (
    id SERIAL PRIMARY KEY,
    checkpoint_name VARCHAR(255) NOT NULL,
    agent_name VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, approved, rejected
    data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP,
    reviewer VARCHAR(100),
    comments TEXT
);

-- Índices para HITL
CREATE INDEX IF NOT EXISTS hitl_checkpoints_status_idx ON hitl_checkpoints(status);
CREATE INDEX IF NOT EXISTS hitl_checkpoints_created_idx ON hitl_checkpoints(created_at DESC);

-- Tabla de sesiones de desarrollo
CREATE TABLE IF NOT EXISTS dev_sessions (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(100) UNIQUE NOT NULL,
    project_type VARCHAR(50), -- greenfield, brownfield
    repo_url TEXT,
    context_file TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    status VARCHAR(50) DEFAULT 'active', -- active, completed, failed
    metadata JSONB
);

-- Tabla de especificaciones generadas
CREATE TABLE IF NOT EXISTS specifications (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(100) REFERENCES dev_sessions(session_id),
    spec_type VARCHAR(100),
    content TEXT NOT NULL,
    version INTEGER DEFAULT 1,
    approved BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP,
    approved_by VARCHAR(100)
);

-- Tabla de planes de implementación
CREATE TABLE IF NOT EXISTS implementation_plans (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(100) REFERENCES dev_sessions(session_id),
    specification_id INTEGER REFERENCES specifications(id),
    plan_content TEXT NOT NULL,
    tasks JSONB,
    approved BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP,
    approved_by VARCHAR(100)
);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para context_embeddings
CREATE TRIGGER update_context_embeddings_updated_at 
BEFORE UPDATE ON context_embeddings 
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at_column();

-- Insertar datos de ejemplo para testing
INSERT INTO dev_sessions (session_id, project_type, status, metadata) 
VALUES ('test-session-001', 'greenfield', 'active', '{"description": "Test session"}')
ON CONFLICT DO NOTHING;

-- Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE '✅ Database initialized successfully with pgvector and audit tables';
END $$;
