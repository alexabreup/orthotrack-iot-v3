INSERT INTO medical_staff (
    institution_id, 
    name, 
    email, 
    phone, 
    role, 
    specialty, 
    department, 
    password_hash, 
    is_active, 
    permissions, 
    created_at, 
    updated_at
) VALUES (
    1, 
    'Master Admin', 
    'master', 
    '(11) 0000-0000', 
    'admin', 
    'Administração', 
    'TI', 
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 
    true, 
    '{"admin": true, "patients": ["read", "write", "delete"], "devices": ["read", "write", "delete"], "reports": ["read", "write", "delete"]}', 
    NOW(), 
    NOW()
);
