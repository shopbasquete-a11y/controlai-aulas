-- Migration: Criar Tabela de Uso de Recursos (Controle de Limites)
-- Descrição: Armazena métricas de uso mensal por empresa para controle de limites do plano

CREATE TABLE IF NOT EXISTS uso_recursos (
    id BIGSERIAL PRIMARY KEY,
    empresa_id BIGINT NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    mes_referencia DATE NOT NULL, -- Formato: YYYY-MM-01 (primeiro dia do mês)
    mensagens_enviadas INTEGER DEFAULT 0,
    tokens_consumidos INTEGER DEFAULT 0,
    agentes_ativos INTEGER DEFAULT 0, -- Contagem de agentes ativos no mês
    usuarios_ativos INTEGER DEFAULT 0, -- Contagem de usuários ativos no mês
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraint: uma única entrada por empresa por mês
    CONSTRAINT unique_empresa_mes UNIQUE (empresa_id, mes_referencia)
);

-- Índices
CREATE INDEX idx_uso_recursos_empresa_id ON uso_recursos(empresa_id);
CREATE INDEX idx_uso_recursos_mes_referencia ON uso_recursos(mes_referencia DESC);
CREATE INDEX idx_uso_recursos_empresa_mes ON uso_recursos(empresa_id, mes_referencia DESC);

-- Trigger para atualizar updated_at
CREATE TRIGGER update_uso_recursos_updated_at
    BEFORE UPDATE ON uso_recursos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Função para obter ou criar registro do mês atual
CREATE OR REPLACE FUNCTION get_or_create_uso_mes_atual(p_empresa_id BIGINT)
RETURNS uso_recursos AS $$
DECLARE
    v_mes_atual DATE;
    v_uso uso_recursos;
BEGIN
    -- Calcula primeiro dia do mês atual
    v_mes_atual := DATE_TRUNC('month', CURRENT_DATE)::DATE;
    
    -- Tenta obter registro existente
    SELECT * INTO v_uso
    FROM uso_recursos
    WHERE empresa_id = p_empresa_id
      AND mes_referencia = v_mes_atual;
    
    -- Se não existe, cria novo registro
    IF v_uso IS NULL THEN
        INSERT INTO uso_recursos (empresa_id, mes_referencia)
        VALUES (p_empresa_id, v_mes_atual)
        RETURNING * INTO v_uso;
    END IF;
    
    RETURN v_uso;
END;
$$ LANGUAGE plpgsql;

-- Comentários
COMMENT ON TABLE uso_recursos IS 'Métricas de uso mensal por empresa para controle de limites';
COMMENT ON COLUMN uso_recursos.mes_referencia IS 'Primeiro dia do mês de referência (YYYY-MM-01)';
COMMENT ON FUNCTION get_or_create_uso_mes_atual IS 'Obtém ou cria registro de uso do mês atual para uma empresa';

