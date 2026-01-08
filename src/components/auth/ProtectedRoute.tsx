import { ReactNode } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useTenant } from '@/contexts/tenant-context';
import { Skeleton } from '@/components/ui/skeleton';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { AlertCircle } from 'lucide-react';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';

interface ProtectedRouteProps {
  children: ReactNode;
  /**
   * Roles permitidos para acessar esta rota
   * Se não especificado, qualquer usuário autenticado pode acessar
   */
  allowedRoles?: ('master' | 'admin' | 'user')[];
  /**
   * Se true, redireciona para login. Se false, mostra mensagem de acesso negado
   */
  redirectToLogin?: boolean;
}

/**
 * Componente de Proteção de Rotas
 * 
 * Verifica autenticação e permissões (roles) antes de renderizar o conteúdo.
 * 
 * @example
 * ```tsx
 * <Route 
 *   path="/admin" 
 *   element={
 *     <ProtectedRoute allowedRoles={['admin', 'master']}>
 *       <AdminPage />
 *     </ProtectedRoute>
 *   } 
 * />
 * ```
 */
export function ProtectedRoute({
  children,
  allowedRoles,
  redirectToLogin = true,
}: ProtectedRouteProps) {
  const { isAuthenticated, isLoading, role } = useTenant();
  const location = useLocation();

  // Mostrar loading enquanto verifica autenticação
  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="w-full max-w-md">
          <CardHeader>
            <CardTitle>Carregando...</CardTitle>
            <CardDescription>Verificando autenticação</CardDescription>
          </CardHeader>
          <CardContent className="space-y-2">
            <Skeleton className="h-4 w-full" />
            <Skeleton className="h-4 w-3/4" />
            <Skeleton className="h-4 w-1/2" />
          </CardContent>
        </Card>
      </div>
    );
  }

  // Se não autenticado, redirecionar para login
  if (!isAuthenticated) {
    if (redirectToLogin) {
      return <Navigate to="/auth/login" state={{ from: location }} replace />;
    }
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Alert variant="destructive" className="max-w-md">
          <AlertCircle className="h-4 w-4" />
          <AlertTitle>Acesso Negado</AlertTitle>
          <AlertDescription>
            Você precisa estar autenticado para acessar esta página.
          </AlertDescription>
        </Alert>
      </div>
    );
  }

  // Se roles especificados, verificar se usuário tem permissão
  if (allowedRoles && role && !allowedRoles.includes(role)) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Alert variant="destructive" className="max-w-md">
          <AlertCircle className="h-4 w-4" />
          <AlertTitle>Acesso Negado</AlertTitle>
          <AlertDescription>
            Você não tem permissão para acessar esta página.
            <br />
            <span className="text-sm text-muted-foreground mt-2 block">
              Role necessário: {allowedRoles.join(' ou ')}
              <br />
              Seu role: {role}
            </span>
          </AlertDescription>
        </Alert>
      </div>
    );
  }

  // Tudo OK, renderizar conteúdo
  return <>{children}</>;
}

