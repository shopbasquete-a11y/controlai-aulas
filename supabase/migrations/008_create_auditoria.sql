-- Migration: Criar Tabela de Auditoria (Logs de Ações Administrativas)
-- Descrição: Armazena logs detalhados de todas as ações administrativas para compliance e segurança

CREATE TABLE IF NOT EXISTS auditoria (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES perfis(id) ON DELETE SET NULL,
    empresa_id BIGINT REFERENCES empresas(id) ON DELETE SET NULL, -- NULL para ações master
    acao VARCHAR(100) NOT NULL, -- Ex: 'create_member', 'update_plan', 'delete_agent'
    entidade_tipo VARCHAR(50) NOT NULL, -- Ex: 'perfil', 'empresa', 'agente_ia'
    entidade_id BIGINT, -- ID da entidade afetada (pode ser NULL)
    detalhes JSONB DEFAULT '{}'::jsonb, -- Dados adicionais da ação
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_auditoria_user_id ON auditoria(user_id);
CREATE INDEX idx_auditoria_empresa_id ON auditoria(empresa_id);
CREATE INDEX idx_auditoria_acao ON auditoria(acao);
CREATE INDEX idx_auditoria_entidade_tipo ON auditoria(entidade_tipo);
CREATE INDEX idx_auditoria_created_at ON auditoria(created_at DESC);
CREATE INDEX idx_auditoria_empresa_created ON auditoria(empresa_id, created_at DESC);

-- Índice GIN para busca em detalhes JSONB
CREATE INDEX idx_auditoria_detalhes_gin ON auditoria USING GIN (detalhes);

-- Comentários
COMMENT ON TABLE auditoria IS 'Logs de todas as ações administrativas para compliance e segurança';
COMMENT ON COLUMN auditoria.empresa_id IS 'ID da empresa (NULL para ações de usuários master)';
COMMENT ON COLUMN auditoria.acao IS 'Tipo de ação executada (ex: create_member, update_plan)';
COMMENT ON COLUMN auditoria.entidade_tipo IS 'Tipo da entidade afetada (ex: perfil, empresa, agente_ia)';
COMMENT ON COLUMN auditoria.detalhes IS 'Dados adicionais da ação em formato JSON';

