import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Link, useNavigate } from "react-router-dom";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { registerSchema, type RegisterFormData } from "@/lib/validations/auth";
import { signUp } from "@/lib/supabase/auth";
import { useState } from "react";
import { toast } from "sonner";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";

export default function Register() {
  const navigate = useNavigate();
  const [isLoading, setIsLoading] = useState(false);

  const form = useForm<RegisterFormData>({
    resolver: zodResolver(registerSchema),
    defaultValues: {
      name: "",
      email: "",
      company: "",
      password: "",
      confirmPassword: "",
    },
  });

  const onSubmit = async (data: RegisterFormData) => {
    setIsLoading(true);
    try {
      // 1. Criar usuário no Supabase Auth
      const { user, session, error: authError } = await signUp(
        data.email,
        data.password,
        {
          nome_completo: data.name,
          nome_empresa: data.company,
        }
      );

      if (authError) {
        console.error("Erro ao criar usuário:", authError);
        toast.error("Erro ao criar conta", {
          description: authError.message,
        });
        return;
      }

      if (!user) {
        toast.error("Erro ao criar conta", {
          description: "Usuário não foi criado",
        });
        return;
      }

      // 2. Verificar se precisa confirmar email
      // Se não houver sessão, pode ser que o email precise ser confirmado
      if (!session) {
        toast.info("Verifique seu email", {
          description: "Enviamos um link de confirmação. Após confirmar, faça login para continuar.",
        });
        navigate("/auth/login");
        return;
      }

      // 3. Provisionar tenant via Edge Function
      if (!session.access_token) {
        toast.error("Erro ao criar conta", {
          description: "Token de acesso não disponível",
        });
        return;
      }

      console.log("Chamando Edge Function provision-tenant...");
      const provisionResponse = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/provision-tenant`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({
            nome_empresa: data.company,
            nome_completo: data.name,
          }),
        }
      );

      // Verificar se a resposta é JSON válido
      let provisionData;
      const contentType = provisionResponse.headers.get("content-type");
      if (contentType && contentType.includes("application/json")) {
        provisionData = await provisionResponse.json();
      } else {
        const text = await provisionResponse.text();
        console.error("Resposta não é JSON:", text);
        toast.error("Erro ao criar empresa", {
          description: `Erro inesperado: ${provisionResponse.status} ${provisionResponse.statusText}`,
        });
        navigate("/auth/login");
        return;
      }

      console.log("Resposta da Edge Function:", provisionData);

      if (!provisionResponse.ok) {
        console.error("Erro ao provisionar tenant:", provisionData);
        const errorMessage = provisionData.error || provisionData.details || `Erro ${provisionResponse.status}`;
        toast.error("Erro ao criar empresa", {
          description: errorMessage,
        });
        // Usuário foi criado, mas empresa não. Pode fazer login e tentar novamente.
        navigate("/auth/login");
        return;
      }

      if (provisionData.error) {
        console.error("Erro na resposta:", provisionData);
        toast.error("Erro ao criar empresa", {
          description: provisionData.error || provisionData.details || "Erro desconhecido",
        });
        navigate("/auth/login");
        return;
      }

      if (!provisionData.success) {
        toast.error("Erro ao criar empresa", {
          description: "Não foi possível criar a empresa. Tente fazer login novamente.",
        });
        navigate("/auth/login");
        return;
      }

      console.log("Tenant provisionado com sucesso:", provisionData);
      toast.success("Conta criada com sucesso!");
      
      // Aguardar um pouco para garantir que os dados foram salvos
      await new Promise(resolve => setTimeout(resolve, 500));
      
      navigate("/dashboard");
    } catch (error) {
      console.error("Erro inesperado no registro:", error);
      toast.error("Erro inesperado", {
        description: error instanceof Error ? error.message : "Tente novamente mais tarde",
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="mb-8 text-center">
          <Link to="/">
            <h1 className="text-3xl font-bold bg-hero-gradient bg-clip-text text-transparent">
              ControlIA.io
            </h1>
          </Link>
        </div>
        
        <Card className="border-border">
          <CardHeader className="space-y-1">
            <CardTitle className="text-2xl">Criar Conta</CardTitle>
            <CardDescription>
              Preencha os dados para começar gratuitamente
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Form {...form}>
              <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
                <FormField
                  control={form.control}
                  name="name"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Nome Completo</FormLabel>
                      <FormControl>
                        <Input
                          type="text"
                          placeholder="João Silva"
                          className="bg-input border-border"
                          {...field}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="company"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Empresa</FormLabel>
                      <FormControl>
                        <Input
                          type="text"
                          placeholder="Minha Empresa Ltda"
                          className="bg-input border-border"
                          {...field}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="email"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Email</FormLabel>
                      <FormControl>
                        <Input
                          type="email"
                          placeholder="seu@email.com"
                          className="bg-input border-border"
                          {...field}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="password"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Senha</FormLabel>
                      <FormControl>
                        <Input
                          type="password"
                          placeholder="••••••••"
                          className="bg-input border-border"
                          {...field}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="confirmPassword"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Confirmar Senha</FormLabel>
                      <FormControl>
                        <Input
                          type="password"
                          placeholder="••••••••"
                          className="bg-input border-border"
                          {...field}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <Button 
                  type="submit" 
                  disabled={isLoading}
                  className="w-full bg-primary text-primary-foreground hover:bg-primary/90 shadow-glow-primary"
                >
                  {isLoading ? "Criando conta..." : "Criar Conta"}
                </Button>
              </form>
            </Form>
            
            <div className="mt-4 text-center text-sm">
              <span className="text-muted-foreground">Já tem uma conta? </span>
              <Link to="/auth/login" className="text-primary hover:underline">
                Faça login
              </Link>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
