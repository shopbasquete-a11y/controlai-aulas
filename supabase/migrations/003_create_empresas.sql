-- Migration: Criar Tabela de Empresas (Tenants)
-- Descrição: Armazena dados das empresas clientes (tenants) do SaaS

CREATE TABLE IF NOT EXISTS empresas (
    id BIGSERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    plano_id BIGINT NOT NULL REFERENCES planos(id) ON DELETE RESTRICT,
    chave_api_llm TEXT, -- Será criptografado via Edge Functions usando pgcrypto
    contexto_ia JSONB DEFAULT '{}'::jsonb, -- System prompt e configurações da IA
    stripe_customer_id VARCHAR(255) UNIQUE,
    email VARCHAR(255),
    telefone VARCHAR(50),
    endereco TEXT,
    status VARCHAR(50) DEFAULT 'ativa', -- ativa, suspensa, cancelada
    data_adesao TIMESTAMPTZ DEFAULT NOW(),
    proxima_cobranca TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_empresas_plano_id ON empresas(plano_id);
CREATE INDEX idx_empresas_stripe_customer_id ON empresas(stripe_customer_id);
CREATE INDEX idx_empresas_status ON empresas(status);
CREATE INDEX idx_empresas_is_active ON empresas(is_active);

-- Trigger para atualizar updated_at
CREATE TRIGGER update_empresas_updated_at
    BEFORE UPDATE ON empresas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentários
COMMENT ON TABLE empresas IS 'Empresas clientes (tenants) do SaaS';
COMMENT ON COLUMN empresas.chave_api_llm IS 'Chave API do LLM criptografada (BYOK)';
COMMENT ON COLUMN empresas.contexto_ia IS 'Configurações e system prompt da IA da empresa';
COMMENT ON COLUMN empresas.stripe_customer_id IS 'ID do cliente no Stripe';

