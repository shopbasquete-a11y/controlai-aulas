-- Migration: Criar Tabela de Conversas (Histórico de Chats)
-- Descrição: Armazena histórico de conversas entre usuários e agentes IA

CREATE TABLE IF NOT EXISTS conversas (
    id BIGSERIAL PRIMARY KEY,
    conversation_uuid UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    empresa_id BIGINT NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES perfis(id) ON DELETE CASCADE,
    agente_id BIGINT NOT NULL REFERENCES agentes_ia(id) ON DELETE RESTRICT,
    titulo VARCHAR(255), -- Título gerado automaticamente ou pelo usuário
    mensagens JSONB DEFAULT '[]'::jsonb, -- Array de mensagens [{role, content, timestamp}]
    tokens_usados INTEGER DEFAULT 0,
    status VARCHAR(50) DEFAULT 'ativa', -- ativa, arquivada, deletada
    contexto_atual JSONB DEFAULT '{}'::jsonb, -- Contexto adicional da conversa
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_conversas_empresa_id ON conversas(empresa_id);
CREATE INDEX idx_conversas_user_id ON conversas(user_id);
CREATE INDEX idx_conversas_agente_id ON conversas(agente_id);
CREATE INDEX idx_conversas_conversation_uuid ON conversas(conversation_uuid);
CREATE INDEX idx_conversas_status ON conversas(status);
CREATE INDEX idx_conversas_created_at ON conversas(created_at DESC);

-- Índice GIN para busca em mensagens JSONB
CREATE INDEX idx_conversas_mensagens_gin ON conversas USING GIN (mensagens);

-- Trigger para atualizar updated_at
CREATE TRIGGER update_conversas_updated_at
    BEFORE UPDATE ON conversas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentários
COMMENT ON TABLE conversas IS 'Histórico de conversas entre usuários e agentes IA';
COMMENT ON COLUMN conversas.conversation_uuid IS 'UUID único para rastreamento da conversa';
COMMENT ON COLUMN conversas.mensagens IS 'Array JSON com histórico de mensagens: [{role: "user"|"assistant", content: string, timestamp: string}]';
COMMENT ON COLUMN conversas.tokens_usados IS 'Total de tokens consumidos nesta conversa';

