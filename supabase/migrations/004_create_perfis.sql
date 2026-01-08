-- Migration: Criar Tabela de Perfis (Colaboradores/Usuários)
-- Descrição: Armazena perfis de usuários vinculados a empresas e ao Supabase Auth

CREATE TABLE IF NOT EXISTS perfis (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    empresa_id BIGINT NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    role role_type NOT NULL DEFAULT 'user',
    email VARCHAR(255) NOT NULL,
    nome_completo VARCHAR(255),
    telefone VARCHAR(50),
    cargo VARCHAR(100),
    status VARCHAR(50) DEFAULT 'ativo', -- ativo, inativo, suspenso
    ultimo_acesso TIMESTAMPTZ,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraint: garantir que email seja único por empresa
    CONSTRAINT unique_email_per_empresa UNIQUE (empresa_id, email)
);

-- Índices
CREATE INDEX idx_perfis_empresa_id ON perfis(empresa_id);
CREATE INDEX idx_perfis_role ON perfis(role);
CREATE INDEX idx_perfis_status ON perfis(status);
CREATE INDEX idx_perfis_email ON perfis(email);

-- Trigger para atualizar updated_at
CREATE TRIGGER update_perfis_updated_at
    BEFORE UPDATE ON perfis
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Função para atualizar ultimo_acesso automaticamente
CREATE OR REPLACE FUNCTION update_ultimo_acesso()
RETURNS TRIGGER AS $$
BEGIN
    NEW.ultimo_acesso = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar ultimo_acesso (será chamado via Edge Function após login)
-- Nota: Este trigger pode ser acionado manualmente ou via Edge Function

-- Comentários
COMMENT ON TABLE perfis IS 'Perfis de colaboradores vinculados a empresas e auth.users';
COMMENT ON COLUMN perfis.id IS 'FK para auth.users.id (mesmo ID do usuário autenticado)';
COMMENT ON COLUMN perfis.empresa_id IS 'FK para empresas - ESSENCIAL para RLS e isolamento multi-tenant';
COMMENT ON COLUMN perfis.role IS 'Role do usuário: master, admin ou user';
