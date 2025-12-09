-- Script SQL para criar usuário admin no OrthoTrack IoT V3
-- Email: admin
-- Senha: admin2025

-- Inserir instituição se não existir
INSERT INTO institutions (uuid, name, code, cnpj, address, city, state, zip_code, phone, email, website, type, status, created_at, updated_at)
SELECT 
    gen_random_uuid(),
    'AACD - Associação de Assistência à Criança Deficiente',
    'AACD-SP',
    '60.945.284/0001-06',
    'Av. Prof. Ascendino Reis, 724 - Vila Clementino, São Paulo - SP',
    'São Paulo',
    'SP',
    '04027-000',
    '(11) 5576-0777',
    'contato@aacd.org.br',
    'https://www.aacd.org.br',
    'hospital',
    'active',
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM institutions WHERE code = 'AACD-SP'
)
RETURNING id;

-- Inserir ou atualizar usuário admin
DO $$
DECLARE
    institution_id INTEGER;
    admin_uuid UUID;
    password_hash TEXT := '$2a$10$PfQbRoH5Ik/Q1xGZvv5ymuIuNGz1lQKciFd2PU7NZfZEVoB6DGZxS';
BEGIN
    -- Obter ID da instituição
    SELECT id INTO institution_id FROM institutions WHERE code = 'AACD-SP' LIMIT 1;
    
    IF institution_id IS NULL THEN
        RAISE EXCEPTION 'Instituição não encontrada';
    END IF;
    
    -- Verificar se usuário admin já existe
    IF EXISTS (SELECT 1 FROM medical_staff WHERE email = 'admin') THEN
        -- Atualizar senha do usuário existente
        UPDATE medical_staff 
        SET 
            password_hash = password_hash,
            is_active = true,
            updated_at = NOW()
        WHERE email = 'admin';
        
        RAISE NOTICE 'Senha do usuário admin atualizada com sucesso!';
    ELSE
        -- Criar novo usuário admin
        admin_uuid := gen_random_uuid();
        
        INSERT INTO medical_staff (
            uuid, institution_id, name, email, phone, role, specialty, department,
            password_hash, is_active, permissions, created_at, updated_at
        ) VALUES (
            admin_uuid,
            institution_id,
            'Administrador Sistema',
            'admin',
            '(11) 5576-0777',
            'admin',
            'Sistema',
            'Administração',
            password_hash,
            true,
            '{"admin": true, "patients": ["read", "write"], "devices": ["read", "write"], "reports": ["read", "write"]}',
            NOW(),
            NOW()
        );
        
        RAISE NOTICE 'Usuário admin criado com sucesso!';
    END IF;
END $$;

-- Verificar resultado
SELECT 
    id,
    email,
    name,
    role,
    is_active,
    created_at
FROM medical_staff 
WHERE email = 'admin';











