-- Migration: Criar Tabela de Planos
-- Descrição: Armazena os planos de assinatura disponíveis (Free, Básico, Empresa, Master)

CREATE TABLE IF NOT EXISTS planos (
    id BIGSERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    preco_mensal DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    max_usuarios INTEGER NOT NULL DEFAULT 1,
    max_agentes INTEGER NOT NULL DEFAULT 1,
    limite_mensagens_mes INTEGER NOT NULL DEFAULT 0,
    stripe_price_id VARCHAR(255) UNIQUE,
    features JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT true,
    cor VARCHAR(7), -- Código hexadecimal da cor (ex: #FF5733)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_planos_stripe_price_id ON planos(stripe_price_id);
CREATE INDEX idx_planos_is_active ON planos(is_active);

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_planos_updated_at
    BEFORE UPDATE ON planos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentários
COMMENT ON TABLE planos IS 'Planos de assinatura disponíveis na plataforma';
COMMENT ON COLUMN planos.stripe_price_id IS 'ID do preço no Stripe (usado para checkout)';
COMMENT ON COLUMN planos.features IS 'JSON com features específicas do plano';

