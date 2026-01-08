# Migrations do Banco de Dados

Este diretório contém todas as migrations SQL do banco de dados do ControlAI.

## Ordem de Aplicação

As migrations devem ser aplicadas na seguinte ordem:

1. `001_create_enum_roles.sql` - Cria enum de roles (master, admin, user)
2. `002_create_planos.sql` - Cria tabela de planos de assinatura
3. `003_create_empresas.sql` - Cria tabela de empresas (tenants)
4. `004_create_perfis.sql` - Cria tabela de perfis (colaboradores)
5. `005_create_agentes_ia.sql` - Cria tabela de agentes IA
6. `006_create_conversas.sql` - Cria tabela de conversas (histórico)
7. `007_create_uso_recursos.sql` - Cria tabela de controle de uso
8. `008_create_auditoria.sql` - Cria tabela de auditoria

## Como Aplicar as Migrations

### Opção 1: Via Supabase Dashboard

1. Acesse o Supabase Dashboard do seu projeto
2. Vá em **SQL Editor**
3. Execute cada migration na ordem listada acima
4. Verifique se não há erros

### Opção 2: Via Supabase CLI

```bash
# Instalar Supabase CLI (se ainda não tiver)
npm install -g supabase

# Login no Supabase
supabase login

# Link ao projeto
supabase link --project-ref seu-project-ref

# Aplicar migrations
supabase db push
```

### Opção 3: Via MCP Supabase

Use o servidor MCP Supabase configurado no projeto para aplicar as migrations.

## Notas Importantes

- **NUNCA** modifique migrations já aplicadas em produção
- Sempre crie novas migrations para alterações
- Teste as migrations em ambiente de desenvolvimento primeiro
- As migrations criam índices, triggers e funções auxiliares
- O RLS (Row-Level Security) será habilitado em migrations futuras (Épico 1)

## Estrutura das Tabelas

### Relacionamentos

```
planos (1) ──< (N) empresas
empresas (1) ──< (N) perfis
empresas (1) ──< (N) agentes_ia
empresas (1) ──< (N) conversas
empresas (1) ──< (N) uso_recursos
perfis (1) ──< (N) conversas
perfis (1) ──< (N) auditoria
agentes_ia (1) ──< (N) conversas
```

### Chaves Primárias

Todas as tabelas usam `BIGSERIAL` (int8) como chave primária, exceto:
- `perfis.id`: BIGINT que referencia `auth.users.id`

### Timestamps

Todas as tabelas possuem:
- `created_at TIMESTAMPTZ DEFAULT NOW()`
- `updated_at TIMESTAMPTZ DEFAULT NOW()` (atualizado via trigger)

