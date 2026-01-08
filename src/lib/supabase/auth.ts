import { supabase } from './client';
import type { User, Session, AuthError } from '@supabase/supabase-js';

/**
 * Funções de Autenticação do Supabase
 * 
 * Este módulo encapsula as operações de autenticação do Supabase Auth,
 * fornecendo uma interface limpa para o restante da aplicação.
 */

export interface AuthResponse {
  user: User | null;
  session: Session | null;
  error: AuthError | null;
}

/**
 * Realiza login do usuário
 */
export async function signIn(email: string, password: string): Promise<AuthResponse> {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  return {
    user: data.user,
    session: data.session,
    error,
  };
}

/**
 * Realiza registro de novo usuário
 * 
 * IMPORTANTE: Após o registro, o tenant deve ser provisionado via Edge Function.
 * O registro apenas cria o usuário no Supabase Auth.
 */
export async function signUp(email: string, password: string, metadata?: {
  nome_completo?: string;
  nome_empresa?: string;
}): Promise<AuthResponse> {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        nome_completo: metadata?.nome_completo,
        nome_empresa: metadata?.nome_empresa,
      },
    },
  });

  return {
    user: data.user,
    session: data.session,
    error,
  };
}

/**
 * Realiza logout do usuário
 */
export async function signOut(): Promise<{ error: AuthError | null }> {
  const { error } = await supabase.auth.signOut();
  return { error };
}

/**
 * Obtém a sessão atual do usuário
 */
export async function getSession(): Promise<Session | null> {
  const { data: { session } } = await supabase.auth.getSession();
  return session;
}

/**
 * Obtém o usuário atual
 */
export async function getCurrentUser(): Promise<User | null> {
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

/**
 * Observa mudanças no estado de autenticação
 * 
 * Útil para atualizar o estado da aplicação quando o usuário faz login/logout
 */
export function onAuthStateChange(
  callback: (event: string, session: Session | null) => void
) {
  return supabase.auth.onAuthStateChange((event, session) => {
    callback(event, session);
  });
}

