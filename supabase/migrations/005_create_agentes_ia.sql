-- Migration: Criar Tabela de Agentes IA
-- Descrição: Armazena agentes IA customizados criados pelas empresas

CREATE TABLE IF NOT EXISTS agentes_ia (
    id BIGSERIAL PRIMARY KEY,
    empresa_id BIGINT NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nome VARCHAR(255) NOT NULL,
    descricao TEXT,
    instrucoes TEXT NOT NULL, -- System prompt específico do agente
    icone_url TEXT,
    is_active BOOLEAN DEFAULT true,
    is_popular BOOLEAN DEFAULT false, -- Destaque para agentes populares
    cor VARCHAR(7), -- Código hexadecimal da cor
    created_by UUID REFERENCES perfis(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_agentes_ia_empresa_id ON agentes_ia(empresa_id);
CREATE INDEX idx_agentes_ia_is_active ON agentes_ia(is_active);
CREATE INDEX idx_agentes_ia_is_popular ON agentes_ia(is_popular);
CREATE INDEX idx_agentes_ia_created_by ON agentes_ia(created_by);

-- Trigger para atualizar updated_at
CREATE TRIGGER update_agentes_ia_updated_at
    BEFORE UPDATE ON agentes_ia
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentários
COMMENT ON TABLE agentes_ia IS 'Agentes IA customizados criados pelas empresas';
COMMENT ON COLUMN agentes_ia.instrucoes IS 'System prompt específico do agente (sobrescreve contexto_ia da empresa se necessário)';
COMMENT ON COLUMN agentes_ia.is_popular IS 'Flag para destacar agentes populares na interface';