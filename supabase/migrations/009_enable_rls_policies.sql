-- Migration: Habilitar RLS e Criar Políticas de Segurança
-- Descrição: Habilita Row-Level Security em todas as tabelas e cria políticas
-- para garantir isolamento multi-tenant baseado em empresa_id

-- ============================================
-- 1. HABILITAR RLS EM TODAS AS TABELAS
-- ============================================

ALTER TABLE planos ENABLE ROW LEVEL SECURITY;
ALTER TABLE empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE perfis ENABLE ROW LEVEL SECURITY;
ALTER TABLE agentes_ia ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversas ENABLE ROW LEVEL SECURITY;
ALTER TABLE uso_recursos ENABLE ROW LEVEL SECURITY;
ALTER TABLE auditoria ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 2. POLÍTICAS PARA TABELA: planos
-- ============================================
-- Planos são públicos (todos podem ler planos ativos)

CREATE POLICY "Todos podem ver planos ativos"
ON planos FOR SELECT
USING (is_active = true);

-- Apenas master pode inserir/atualizar planos (via Edge Functions com service_role)
-- Não criamos políticas INSERT/UPDATE aqui pois serão feitas via service_role

-- ============================================
-- 3. POLÍTICAS PARA TABELA: empresas
-- ============================================

-- SELECT: Usuário vê apenas sua própria empresa OU é master
CREATE POLICY "Usuários veem apenas sua empresa"
ON empresas FOR SELECT
USING (
  id IN (
    SELECT empresa_id FROM perfis WHERE id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM perfis 
    WHERE id = auth.uid() AND role = 'master'
  )
);

-- UPDATE: Apenas admin da empresa ou master pode atualizar
CREATE POLICY "Apenas admin pode atualizar sua empresa"
ON empresas FOR UPDATE
USING (
  id IN (
    SELECT empresa_id FROM perfis 
    WHERE id = auth.uid() AND role IN ('admin', 'master')
  )
  OR EXISTS (
    SELECT 1 FROM perfis 
    WHERE id = auth.uid() AND role = 'master'
  )
);

-- INSERT/DELETE: Apenas via Edge Functions (service_role)
-- Não criamos políticas aqui pois serão feitas via service_role

-- ============================================
-- 4. POLÍTICAS PARA TABELA: perfis
-- ============================================

-- SELECT: Usuário vê perfis da sua empresa OU é master
CREATE POLICY "Usuários veem perfis da sua empresa"
ON perfis FOR SELECT
USING (
  empresa_id IN (
    SELECT empresa_id FROM perfis WHERE id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM perfis 
    WHERE id = auth.uid() AND role = 'master'
  )
);

-- INSERT: Apenas admin da empresa ou master pode criar perfis
CREATE POLICY "Apenas admin pode criar perfis"
ON perfis FOR INSERT
WITH CHECK (
  empresa_id IN (
    SELECT empresa_id FROM perfis 
    WHERE id = auth.uid() AND role IN ('admin', 'master')
  )
  OR EXISTS (
    SELECT 1 FROM perfis 
    WHERE id = auth.uid() AND role = 'master'
  )
);

-- UPDATE: Apenas admin da empresa, o próprio usuário ou master pode atualizar
CREATE POLICY "Apenas admin ou próprio usuário pode atualizar perfil"
ON perfis FOR UPDATE
USING (
  id = auth.uid()
  OR empresa_id IN (
    SELECT empresa_id FROM perfis 
    WHERE id = auth.uid() AND role IN ('admin', 'master')
  )
  OR EXISTS (
    SELECT 1 FROM perfis 
    WHERE id = auth.uid() AND role = 'master'
  )
);

-- DELETE: Apenas admin da empresa ou master pode deletar
CREATE POLICY "Apenas admin pode deletar perfis"
ON perfis FOR DELETE
USING (
  empresa_id IN (
    SELECT empresa_id FROM perfis 
    WHERE id = auth.uid() AND role IN ('admin', 'master')
  )
  OR EXISTS (
    SELECT 1 FROM perfis 
    WHERE id = auth.uid() AND role = 'master'
  )
);

-- ============================================
-- 5. POLÍTICAS PARA TABELA: agentes_ia
-- ============================================

-- SELECT: Usuário vê agentes da sua empresa OU é master
CREATE POLICY "Usuários veem agentes da sua empresa"
ON agentes_ia FOR SELECT
USING (
  empresa_id IN (
    SELECT empresa_id FROM perfis WHERE id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM perfis 
    WHERE id = auth.uid() AND role = 'master'
  )
);

-- INSERT: Apenas admin da empresa ou master pode criar agentes
CREATE POLICY "Apenas admin pode criar agentes"
ON agentes_ia FOR INSERT
WITH CHECK (
  empresa_id IN (
    SELECT empresa_id FROM perfis 
    WHERE id = auth.uid() AND role IN ('admin', 'master')
  )
  OR EXISTS (
    SELECT 1 FROM perfis 
    WHERE id = auth.uid() AND role = 'master'
  )
);

-- UPDATE: Apenas admin da empresa ou master pode atualizar
CREATE POLICY "Apenas admin pode atualizar agentes"
ON agentes_ia FOR UPDATE
USING (
  empresa_id IN (
    SELECT empresa_id FROM perfis 
    WHERE id = auth.uid() AND role IN ('admin', 'master')
  )
  OR EXISTS (
    SELECT 1 FROM perfis 
    WHERE id = auth.uid() AND role = 'master'
  )
);

-- DELETE: Apenas admin da empresa ou master pode deletar
CREATE POLICY "Apenas admin pode deletar agentes"
ON agentes_ia FOR DELETE
USING (
  empresa_id IN (
    SELECT empresa_id FROM perfis 
    WHERE id = auth.uid() AND role IN ('admin', 'master')
  )
  OR EXISTS (
    SELECT 1 FROM perfis 
    WHERE id = auth.uid() AND role = 'master'
  )
);

-- ============================================
-- 6. POLÍTICAS PARA TABELA: conversas
-- ============================================

-- SELECT: Usuário vê conversas da sua empresa OU é master
CREATE POLICY "Usuários veem conversas da sua empresa"
ON conversas FOR SELECT
USING (
  empresa_id IN (
    SELECT empresa_id FROM perfis WHERE id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM perfis 
    WHERE id = auth.uid() AND role = 'master'
  )
);

-- INSERT: Usuário pode criar conversas na sua empresa
CREATE POLICY "Usuários podem criar conversas na sua empresa"
ON conversas FOR INSERT
WITH CHECK (
  empresa_id IN (
    SELECT empresa_id FROM perfis WHERE id = auth.uid()
  )
  AND user_id = auth.uid()
);

-- UPDATE: Usuário pode atualizar suas próprias conversas OU admin/master
CREATE POLICY "Usuários podem atualizar suas conversas"
ON conversas FOR UPDATE
USING (
  user_id = auth.uid()
  OR empresa_id IN (
    SELECT empresa_id FROM perfis 
    WHERE id = auth.uid() AND role IN ('admin', 'master')
  )
  OR EXISTS (
    SELECT 1 FROM perfis 
    WHERE id = auth.uid() AND role = 'master'
  )
);

-- DELETE: Usuário pode deletar suas próprias conversas OU admin/master
CREATE POLICY "Usuários podem deletar suas conversas"
ON conversas FOR DELETE
USING (
  user_id = auth.uid()
  OR empresa_id IN (
    SELECT empresa_id FROM perfis 
    WHERE id = auth.uid() AND role IN ('admin', 'master')
  )
  OR EXISTS (
    SELECT 1 FROM perfis 
    WHERE id = auth.uid() AND role = 'master'
  )
);

-- ============================================
-- 7. POLÍTICAS PARA TABELA: uso_recursos
-- ============================================

-- SELECT: Usuário vê uso da sua empresa OU é master
CREATE POLICY "Usuários veem uso da sua empresa"
ON uso_recursos FOR SELECT
USING (
  empresa_id IN (
    SELECT empresa_id FROM perfis WHERE id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM perfis 
    WHERE id = auth.uid() AND role = 'master'
  )
);

-- INSERT/UPDATE: Apenas via Edge Functions (service_role)
-- Não criamos políticas aqui pois serão feitas via service_role

-- ============================================
-- 8. POLÍTICAS PARA TABELA: auditoria
-- ============================================

-- SELECT: Usuário vê auditoria da sua empresa OU é master
CREATE POLICY "Usuários veem auditoria da sua empresa"
ON auditoria FOR SELECT
USING (
  (empresa_id IN (
    SELECT empresa_id FROM perfis WHERE id = auth.uid()
  ))
  OR EXISTS (
    SELECT 1 FROM perfis 
    WHERE id = auth.uid() AND role = 'master'
  )
  OR empresa_id IS NULL -- Master pode ver auditoria sem empresa_id
);

-- INSERT: Apenas via Edge Functions (service_role)
-- Não criamos política INSERT aqui pois será feita via service_role

-- ============================================
-- COMENTÁRIOS FINAIS
-- ============================================

COMMENT ON POLICY "Todos podem ver planos ativos" ON planos IS 
'Permite que todos os usuários autenticados vejam planos ativos';

COMMENT ON POLICY "Usuários veem apenas sua empresa" ON empresas IS 
'Isolamento multi-tenant: usuário só vê dados da sua empresa, exceto master';

COMMENT ON POLICY "Usuários veem perfis da sua empresa" ON perfis IS 
'Isolamento multi-tenant: usuário só vê perfis da sua empresa, exceto master';

COMMENT ON POLICY "Usuários veem agentes da sua empresa" ON agentes_ia IS 
'Isolamento multi-tenant: usuário só vê agentes da sua empresa, exceto master';

COMMENT ON POLICY "Usuários veem conversas da sua empresa" ON conversas IS 
'Isolamento multi-tenant: usuário só vê conversas da sua empresa, exceto master';

COMMENT ON POLICY "Usuários veem uso da sua empresa" ON uso_recursos IS 
'Isolamento multi-tenant: usuário só vê uso da sua empresa, exceto master';