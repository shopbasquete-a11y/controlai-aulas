-- Script para inserir/atualizar todos os planos
-- Execute este script no Supabase Dashboard > SQL Editor

-- Inserir ou atualizar todos os planos
INSERT INTO planos (nome, preco_mensal, max_usuarios, max_agentes, limite_mensagens_mes, is_active, features)
VALUES 
  (
    'Free', 
    0.00, 
    3, 
    1, 
    100, 
    true, 
    '{"suporte": "email", "dashboard": "básico", "seguranca": "completa"}'::jsonb
  ),
  (
    'Básico', 
    99.00, 
    10, 
    3, 
    500, 
    true, 
    '{"suporte": "email", "dashboard": "gestão", "seguranca": "completa"}'::jsonb
  ),
  (
    'Empresa', 
    299.00, 
    50, 
    10, 
    2000, 
    true, 
    '{"suporte": "prioritário", "dashboard": "avançado", "analytics": true, "customizacao": true, "gestao_departamento": true}'::jsonb
  ),
  (
    'Master', 
    0.00, 
    999999, 
    999999, 
    999999, 
    true, 
    '{"suporte": "24/7", "sla": true, "onboarding": "personalizado", "infraestrutura": "dedicada"}'::jsonb
  )
ON CONFLICT (nome) DO UPDATE SET
  preco_mensal = EXCLUDED.preco_mensal,
  max_usuarios = EXCLUDED.max_usuarios,
  max_agentes = EXCLUDED.max_agentes,
  limite_mensagens_mes = EXCLUDED.limite_mensagens_mes,
  features = EXCLUDED.features,
  updated_at = NOW();

-- Verificar planos criados
SELECT 
  nome, 
  preco_mensal, 
  max_usuarios, 
  max_agentes,
  limite_mensagens_mes, 
  is_active 
FROM planos 
ORDER BY 
  CASE nome
    WHEN 'Free' THEN 1
    WHEN 'Básico' THEN 2
    WHEN 'Empresa' THEN 3
    WHEN 'Master' THEN 4
  END;
