/**
 * Tipos do Banco de Dados Supabase
 * 
 * Este arquivo será preenchido automaticamente após a geração de tipos.
 * Execute: npx supabase gen types typescript --project-id <project-id> > src/lib/supabase/types.ts
 * 
 * Por enquanto, definimos tipos básicos baseados no PRD.
 */

export type Role = 'master' | 'admin' | 'user';

export interface Plano {
  id: number;
  nome: string;
  preco_mensal: number;
  max_usuarios: number;
  max_agentes: number;
  limite_mensagens_mes: number;
  stripe_price_id: string | null;
  features: Record<string, unknown> | null;
  is_active: boolean;
  cor: string | null;
  created_at: string;
  updated_at: string;
}

export interface Empresa {
  id: number;
  nome: string;
  plano_id: number;
  chave_api_llm: string | null; // Criptografado
  contexto_ia: Record<string, unknown> | null;
  stripe_customer_id: string | null;
  email: string | null;
  telefone: string | null;
  endereco: string | null;
  status: string;
  data_adesao: string | null;
  proxima_cobranca: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Perfil {
  id: number;
  empresa_id: number;
  role: Role;
  email: string;
  nome_completo: string | null;
  telefone: string | null;
  cargo: string | null;
  status: string;
  ultimo_acesso: string | null;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface AgenteIA {
  id: number;
  empresa_id: number;
  nome: string;
  descricao: string | null;
  instrucoes: string; // System prompt
  icone_url: string | null;
  is_active: boolean;
  is_popular: boolean;
  cor: string | null;
  created_by: number | null;
  created_at: string;
  updated_at: string;
}

export interface Conversa {
  id: number;
  conversation_uuid: string;
  empresa_id: number;
  user_id: number;
  agente_id: number;
  titulo: string | null;
  mensagens: Record<string, unknown> | null;
  tokens_usados: number | null;
  status: string;
  contexto_atual: Record<string, unknown> | null;
  created_at: string;
  updated_at: string;
}

export interface UsoRecursos {
  id: number;
  empresa_id: number;
  mes_referencia: string; // DATE format YYYY-MM-01
  mensagens_enviadas: number;
  tokens_consumidos: number;
  agentes_ativos: number | null;
  usuarios_ativos: number | null;
  created_at: string;
  updated_at: string;
}

export interface Auditoria {
  id: number;
  user_id: number;
  empresa_id: number | null;
  acao: string;
  entidade_tipo: string;
  entidade_id: number | null;
  detalhes: Record<string, unknown> | null;
  ip_address: string | null;
  user_agent: string | null;
  created_at: string;
}

