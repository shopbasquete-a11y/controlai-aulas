-- Migration: Criar Enum de Roles
-- Descrição: Define os tipos de roles disponíveis no sistema (master, admin, user)

-- Criar tipo ENUM para roles
CREATE TYPE role_type AS ENUM ('master', 'admin', 'user');

-- Comentários para documentação
COMMENT ON TYPE role_type IS 'Tipos de roles de usuário: master (dono da plataforma), admin (administrador da empresa), user (colaborador)';

