import { createClient } from '@supabase/supabase-js';

/**
 * Configuração do Cliente Supabase para o ControlAI
 * 
 * Este cliente é usado no frontend (browser) e utiliza a chave anon_key.
 * Para operações sensíveis, utilize Edge Functions que usam service_role.
 * 
 * Variáveis de ambiente necessárias:
 * - VITE_SUPABASE_URL: URL do projeto Supabase
 * - VITE_SUPABASE_ANON_KEY: Chave pública (anon) do Supabase
 */

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl) {
  throw new Error('Missing env.VITE_SUPABASE_URL');
}

if (!supabaseAnonKey) {
  throw new Error('Missing env.VITE_SUPABASE_ANON_KEY');
}

/**
 * Cliente Supabase para uso no frontend
 * 
 * IMPORTANTE: Este cliente usa a chave anon_key e está sujeito às políticas RLS.
 * Nunca use este cliente para operações que requerem privilégios elevados.
 * Para operações administrativas ou sensíveis, utilize Edge Functions.
 */
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
  },
});

/**
 * Tipo do banco de dados (gerado automaticamente pelo Supabase CLI)
 * 
 * Para gerar tipos atualizados, execute:
 * npx supabase gen types typescript --project-id <project-id> > src/lib/supabase/database.types.ts
 */
export type Database = {
  // Tipos serão gerados automaticamente após migrations
};

