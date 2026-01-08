import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { supabase } from '@/lib/supabase/client';
import { getCurrentUser, getSession, onAuthStateChange } from '@/lib/supabase/auth';
import type { Perfil, Empresa } from '@/lib/supabase/types';
import type { User, Session } from '@supabase/supabase-js';

/**
 * Context de Tenant
 * 
 * Gerencia o estado do tenant atual, perfil do usuário e empresa.
 * Fornece hooks para acessar esses dados em qualquer componente.
 */

interface TenantContextValue {
  user: User | null;
  session: Session | null;
  perfil: Perfil | null;
  empresa: Empresa | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  role: 'master' | 'admin' | 'user' | null;
  empresaId: number | null;
  refreshTenant: () => Promise<void>;
}

const TenantContext = createContext<TenantContextValue | undefined>(undefined);

interface TenantProviderProps {
  children: ReactNode;
}

export function TenantProvider({ children }: TenantProviderProps) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [perfil, setPerfil] = useState<Perfil | null>(null);
  const [empresa, setEmpresa] = useState<Empresa | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  /**
   * Carrega dados do tenant (perfil e empresa)
   */
  const loadTenantData = async (userId: string) => {
    try {
      // Buscar perfil
      // Nota: Supabase retorna id como string quando é bigint, então convertemos
      const { data: perfilData, error: perfilError } = await supabase
        .from('perfis')
        .select('*')
        .eq('id', userId)
        .single();

      if (perfilError || !perfilData) {
        console.error('Erro ao carregar perfil:', perfilError);
        setPerfil(null);
        setEmpresa(null);
        return;
      }

      setPerfil(perfilData as Perfil);

      // Buscar empresa
      const { data: empresaData, error: empresaError } = await supabase
        .from('empresas')
        .select('*')
        .eq('id', perfilData.empresa_id)
        .single();

      if (empresaError || !empresaData) {
        console.error('Erro ao carregar empresa:', empresaError);
        setEmpresa(null);
        return;
      }

      setEmpresa(empresaData as Empresa);
    } catch (error) {
      console.error('Erro ao carregar dados do tenant:', error);
      setPerfil(null);
      setEmpresa(null);
    }
  };

  /**
   * Atualiza estado baseado na sessão atual
   */
  const updateAuthState = async () => {
    setIsLoading(true);
    try {
      const currentSession = await getSession();
      const currentUser = await getCurrentUser();

      setSession(currentSession);
      setUser(currentUser);

      if (currentUser) {
        await loadTenantData(currentUser.id);
      } else {
        setPerfil(null);
        setEmpresa(null);
      }
    } catch (error) {
      console.error('Erro ao atualizar estado de autenticação:', error);
      setUser(null);
      setSession(null);
      setPerfil(null);
      setEmpresa(null);
    } finally {
      setIsLoading(false);
    }
  };

  /**
   * Força atualização dos dados do tenant
   */
  const refreshTenant = async () => {
    if (user) {
      await loadTenantData(user.id);
    }
  };

  // Carregar estado inicial
  useEffect(() => {
    updateAuthState();
  }, []);

  // Observar mudanças no estado de autenticação
  useEffect(() => {
    const { data: { subscription } } = onAuthStateChange(async (event, session) => {
      console.log('Auth state changed:', event, session?.user?.id);
      
      if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
        setSession(session);
        setUser(session?.user ?? null);
        if (session?.user) {
          await loadTenantData(session.user.id);
        }
      } else if (event === 'SIGNED_OUT') {
        setUser(null);
        setSession(null);
        setPerfil(null);
        setEmpresa(null);
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const value: TenantContextValue = {
    user,
    session,
    perfil,
    empresa,
    isLoading,
    isAuthenticated: !!user && !!session,
    role: perfil?.role ?? null,
    empresaId: perfil?.empresa_id ?? null,
    refreshTenant,
  };

  return (
    <TenantContext.Provider value={value}>
      {children}
    </TenantContext.Provider>
  );
}

/**
 * Hook para acessar o contexto do tenant
 * 
 * @throws {Error} Se usado fora do TenantProvider
 */
export function useTenant() {
  const context = useContext(TenantContext);
  if (context === undefined) {
    throw new Error('useTenant deve ser usado dentro de um TenantProvider');
  }
  return context;
}

