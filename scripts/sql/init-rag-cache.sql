CREATE TABLE IF NOT EXISTS rag_response_cache (
    cache_key VARCHAR(64) PRIMARY KEY,
    request_type VARCHAR(20) NOT NULL,
    question TEXT NOT NULL,
    log_text TEXT NOT NULL DEFAULT '',
    response_json JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rag_response_cache_created_at
    ON rag_response_cache (created_at);

CREATE INDEX IF NOT EXISTS idx_rag_response_cache_request_type
    ON rag_response_cache (request_type);