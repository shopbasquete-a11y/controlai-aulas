import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

/**
 * Edge Function: Provision Tenant
 * 
 * Esta função é chamada após o registro de um novo usuário no Supabase Auth.
 * Ela cria:
 * 1. Um registro na tabela empresas (tenant)
 * 2. Um perfil na tabela perfis com role 'admin'
 * 
 * Requer autenticação (token JWT válido).
 */

const schema = z.object({
  nome_empresa: z.string().min(2).max(255),
  nome_completo: z.string().min(2).max(255),
});

serve(async (req) => {
  // CORS headers
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, content-type",
      },
    });
  }

  try {
    // 1. Verificar autenticação
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        {
          status: 401,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // 2. Criar cliente Supabase com service_role para bypass RLS
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // 3. Verificar token e obter usuário
    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired token" }),
        {
          status: 401,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // 4. Validar entrada
    const body = await req.json();
    const validatedData = schema.parse(body);

    // 5. Verificar se perfil já existe (evitar duplicação)
    const { data: existingProfile } = await supabase
      .from("perfis")
      .select("id, empresa_id")
      .eq("id", user.id)
      .single();

    if (existingProfile) {
      return new Response(
        JSON.stringify({
          error: "Profile already exists",
          empresa_id: existingProfile.empresa_id,
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // 6. Obter plano "Free" (plano padrão)
    const { data: planoFree, error: planoError } = await supabase
      .from("planos")
      .select("id")
      .eq("nome", "Free")
      .eq("is_active", true)
      .single();

    if (planoError || !planoFree) {
      return new Response(
        JSON.stringify({
          error: "Plano Free não encontrado. Configure os planos primeiro.",
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // 7. Criar empresa (tenant)
    const { data: empresa, error: empresaError } = await supabase
      .from("empresas")
      .insert({
        nome: validatedData.nome_empresa,
        plano_id: planoFree.id,
        email: user.email,
        status: "ativa",
        is_active: true,
      })
      .select()
      .single();

    if (empresaError || !empresa) {
      console.error("Erro ao criar empresa:", empresaError);
      return new Response(
        JSON.stringify({
          error: "Failed to create empresa",
          details: empresaError?.message,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // 8. Criar perfil com role 'admin'
    const { data: perfil, error: perfilError } = await supabase
      .from("perfis")
      .insert({
        id: BigInt(user.id),
        empresa_id: empresa.id,
        role: "admin",
        email: user.email!,
        nome_completo: validatedData.nome_completo,
        status: "ativo",
      })
      .select()
      .single();

    if (perfilError || !perfil) {
      // Rollback: deletar empresa criada
      await supabase.from("empresas").delete().eq("id", empresa.id);

      console.error("Erro ao criar perfil:", perfilError);
      return new Response(
        JSON.stringify({
          error: "Failed to create perfil",
          details: perfilError?.message,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // 9. Retornar sucesso
    return new Response(
      JSON.stringify({
        success: true,
        empresa: {
          id: empresa.id,
          nome: empresa.nome,
          plano_id: empresa.plano_id,
        },
        perfil: {
          id: perfil.id,
          role: perfil.role,
          empresa_id: perfil.empresa_id,
        },
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error) {
    console.error("Erro na função provision-tenant:", error);

    if (error instanceof z.ZodError) {
      return new Response(
        JSON.stringify({
          error: "Invalid request data",
          details: error.errors,
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    return new Response(
      JSON.stringify({
        error: "Internal server error",
        details: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});

