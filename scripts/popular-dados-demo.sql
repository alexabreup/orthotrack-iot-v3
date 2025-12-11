-- Script para Popular Banco com Dados de Demonstração
-- OrthoTrack IoT Platform v3

-- ============================================
-- 1. INSTITUIÇÕES
-- ============================================
INSERT INTO institutions (name, code, cnpj, city, state, type, status, created_at, updated_at)
VALUES 
  ('AACD São Paulo', 'AACD-SP', '60.979.457/0001-11', 'São Paulo', 'SP', 'hospital', 'active', NOW(), NOW()),
  ('AACD Recife', 'AACD-RE', '60.979.457/0002-92', 'Recife', 'PE', 'hospital', 'active', NOW(), NOW())
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- 2. PROFISSIONAIS DE SAÚDE
-- ============================================
INSERT INTO medical_staff (institution_id, name, email, crm, crm_state, specialty, role, password_hash, is_active, created_at, updated_at)
VALUES 
  (1, 'Dr. Carlos Silva', 'carlos.silva@aacd.org.br', '123456', 'SP', 'Ortopedia', 'physician', '$2a$10$YourHashedPasswordHere', true, NOW(), NOW()),
  (1, 'Dra. Maria Santos', 'maria.santos@aacd.org.br', '789012', 'SP', 'Fisioterapia', 'physiotherapist', '$2a$10$YourHashedPasswordHere', true, NOW(), NOW()),
  (2, 'Dr. João Oliveira', 'joao.oliveira@aacd.org.br', '345678', 'PE', 'Ortopedia', 'physician', '$2a$10$YourHashedPasswordHere', true, NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

-- ============================================
-- 3. PACIENTES
-- ============================================
INSERT INTO patients (
  external_id, institution_id, medical_staff_id,
  name, date_of_birth, gender, cpf, email, phone,
  medical_record, diagnosis_code, severity_level, scoliosis_type,
  prescription_hours, daily_usage_target_minutes,
  treatment_start, status, is_active,
  consent_given_at, legal_basis,
  created_at, updated_at
)
VALUES 
  -- Paciente 1: João Silva (Demo Principal)
  (
    'PAT-DEMO-001', 1, 1,
    'João Silva', '2010-05-15', 'M', '123.456.789-00', 'joao.silva@email.com', '(11) 98765-4321',
    'MR-2024-001', 'M41.1', 4, 'Escoliose Idiopática Juvenil',
    16, 960,
    '2024-01-15', 'active', true,
    NOW(), 'medical_treatment',
    NOW(), NOW()
  ),
  
  -- Paciente 2: Maria Oliveira
  (
    'PAT-DEMO-002', 1, 1,
    'Maria Oliveira', '2012-08-22', 'F', '987.654.321-00', 'maria.oliveira@email.com', '(11) 91234-5678',
    'MR-2024-002', 'M41.2', 3, 'Escoliose Idiopática Adolescente',
    14, 840,
    '2024-02-01', 'active', true,
    NOW(), 'medical_treatment',
    NOW(), NOW()
  ),
  
  -- Paciente 3: Pedro Santos
  (
    'PAT-DEMO-003', 1, 2,
    'Pedro Santos', '2011-11-30', 'M', '456.789.123-00', 'pedro.santos@email.com', '(11) 99876-5432',
    'MR-2024-003', 'M41.1', 5, 'Escoliose Idiopática Juvenil',
    18, 1080,
    '2024-03-10', 'active', true,
    NOW(), 'medical_treatment',
    NOW(), NOW()
  ),
  
  -- Paciente 4: Ana Costa (Recife)
  (
    'PAT-DEMO-004', 2, 3,
    'Ana Costa', '2013-03-18', 'F', '321.654.987-00', 'ana.costa@email.com', '(81) 98765-1234',
    'MR-2024-004', 'M41.2', 2, 'Escoliose Idiopática Adolescente',
    12, 720,
    '2024-04-05', 'active', true,
    NOW(), 'medical_treatment',
    NOW(), NOW()
  ),
  
  -- Paciente 5: Lucas Ferreira
  (
    'PAT-DEMO-005', 1, 1,
    'Lucas Ferreira', '2009-07-25', 'M', '789.123.456-00', 'lucas.ferreira@email.com', '(11) 97654-3210',
    'MR-2024-005', 'M41.1', 4, 'Escoliose Idiopática Juvenil',
    16, 960,
    '2024-05-20', 'active', true,
    NOW(), 'medical_treatment',
    NOW(), NOW()
  )
ON CONFLICT (external_id) DO NOTHING;

-- ============================================
-- 4. DISPOSITIVOS (BRACES)
-- ============================================
INSERT INTO braces (
  device_id, serial_number, mac_address, patient_id,
  model, version, firmware_version, hardware_version,
  status, battery_level, signal_strength,
  last_heartbeat, last_seen,
  manufactured_date, activated_date,
  created_at, updated_at
)
VALUES 
  -- Dispositivo 1: ESP32-DEMO-001 (João Silva)
  (
    'ESP32-DEMO-001', 'SN-2024-001', '00:1A:2B:3C:4D:01', 1,
    'ESP32-ORTHO-V1', '1.0', '3.0.0', '1.0',
    'online', 85, -45,
    NOW(), NOW(),
    '2024-01-01', '2024-01-15',
    NOW(), NOW()
  ),
  
  -- Dispositivo 2: ESP32-DEMO-002 (Maria Oliveira)
  (
    'ESP32-DEMO-002', 'SN-2024-002', '00:1A:2B:3C:4D:02', 2,
    'ESP32-ORTHO-V1', '1.0', '3.0.0', '1.0',
    'online', 92, -38,
    NOW() - INTERVAL '5 minutes', NOW() - INTERVAL '5 minutes',
    '2024-01-01', '2024-02-01',
    NOW(), NOW()
  ),
  
  -- Dispositivo 3: ESP32-DEMO-003 (Pedro Santos)
  (
    'ESP32-DEMO-003', 'SN-2024-003', '00:1A:2B:3C:4D:03', 3,
    'ESP32-ORTHO-V1', '1.0', '3.0.0', '1.0',
    'offline', 15, -75,
    NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours',
    '2024-01-01', '2024-03-10',
    NOW(), NOW()
  ),
  
  -- Dispositivo 4: ESP32-DEMO-004 (Ana Costa)
  (
    'ESP32-DEMO-004', 'SN-2024-004', '00:1A:2B:3C:4D:04', 4,
    'ESP32-ORTHO-V1', '1.0', '3.0.0', '1.0',
    'online', 78, -42,
    NOW() - INTERVAL '1 minute', NOW() - INTERVAL '1 minute',
    '2024-01-01', '2024-04-05',
    NOW(), NOW()
  ),
  
  -- Dispositivo 5: ESP32-DEMO-005 (Lucas Ferreira)
  (
    'ESP32-DEMO-005', 'SN-2024-005', '00:1A:2B:3C:4D:05', 5,
    'ESP32-ORTHO-V1', '1.0', '3.0.0', '1.0',
    'maintenance', 100, 0,
    NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day',
    '2024-01-01', '2024-05-20',
    NOW(), NOW()
  )
ON CONFLICT (device_id) DO NOTHING;

-- ============================================
-- 5. LEITURAS DE SENSORES (Últimas 24h)
-- ============================================
-- Gerar leituras para dispositivos online
DO $$
DECLARE
  i INTEGER;
  device_ids TEXT[] := ARRAY['ESP32-DEMO-001', 'ESP32-DEMO-002', 'ESP32-DEMO-004'];
  device_id TEXT;
  brace_id INTEGER;
BEGIN
  FOREACH device_id IN ARRAY device_ids
  LOOP
    -- Buscar ID do brace
    SELECT id INTO brace_id FROM braces WHERE device_id = device_id;
    
    -- Gerar 288 leituras (1 a cada 5 minutos nas últimas 24h)
    FOR i IN 0..287 LOOP
      INSERT INTO sensor_readings (
        brace_id, timestamp,
        accel_x, accel_y, accel_z,
        gyro_x, gyro_y, gyro_z,
        temperature, humidity, pressure_value,
        brace_closed, is_wearing,
        battery_voltage, signal_strength,
        created_at
      )
      VALUES (
        brace_id,
        NOW() - (i * INTERVAL '5 minutes'),
        (RANDOM() * 2 - 1)::NUMERIC(10,6),  -- -1 a 1 m/s²
        (RANDOM() * 2 - 1)::NUMERIC(10,6),
        (9.8 + RANDOM() * 0.4 - 0.2)::NUMERIC(10,6),  -- ~9.8 m/s²
        (RANDOM() * 0.2 - 0.1)::NUMERIC(10,6),  -- rad/s
        (RANDOM() * 0.2 - 0.1)::NUMERIC(10,6),
        (RANDOM() * 0.2 - 0.1)::NUMERIC(10,6),
        (35.0 + RANDOM() * 3)::NUMERIC(5,2),  -- 35-38°C
        (45.0 + RANDOM() * 10)::NUMERIC(5,2),  -- 45-55%
        (CASE WHEN RANDOM() > 0.3 THEN 1 ELSE 0 END),  -- 70% usando
        (CASE WHEN RANDOM() > 0.3 THEN true ELSE false END),
        (CASE WHEN RANDOM() > 0.3 THEN true ELSE false END),
        (3.7 + RANDOM() * 0.5)::NUMERIC(4,2),  -- 3.7-4.2V
        (-40 - RANDOM() * 20)::INTEGER,  -- -40 a -60 dBm
        NOW() - (i * INTERVAL '5 minutes')
      );
    END LOOP;
  END LOOP;
END $$;

-- ============================================
-- 6. SESSÕES DE USO
-- ============================================
-- Sessões de hoje
INSERT INTO usage_sessions (
  brace_id, patient_id,
  start_time, end_time, duration, is_active,
  avg_movement_level, avg_posture_score, compliance_score,
  created_at, updated_at
)
VALUES 
  -- João Silva - Sessão ativa
  (1, 1, NOW() - INTERVAL '3 hours', NULL, 10800, true, 'medium', 85.5, 95.0, NOW(), NOW()),
  
  -- Maria Oliveira - Sessão completa
  (2, 2, NOW() - INTERVAL '8 hours', NOW() - INTERVAL '2 hours', 21600, false, 'low', 92.3, 98.5, NOW(), NOW()),
  
  -- Ana Costa - Sessão ativa
  (4, 4, NOW() - INTERVAL '5 hours', NULL, 18000, true, 'medium', 88.7, 96.2, NOW(), NOW());

-- Sessões de ontem
INSERT INTO usage_sessions (
  brace_id, patient_id,
  start_time, end_time, duration, is_active,
  avg_movement_level, avg_posture_score, compliance_score,
  created_at, updated_at
)
VALUES 
  (1, 1, NOW() - INTERVAL '1 day 8 hours', NOW() - INTERVAL '1 day', 28800, false, 'medium', 87.2, 100.0, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
  (2, 2, NOW() - INTERVAL '1 day 7 hours', NOW() - INTERVAL '1 day 1 hour', 21600, false, 'low', 91.5, 96.4, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day');

-- ============================================
-- 7. COMPLIANCE DIÁRIO
-- ============================================
-- Últimos 7 dias
DO $$
DECLARE
  i INTEGER;
  patient_ids INTEGER[] := ARRAY[1, 2, 3, 4, 5];
  patient_id INTEGER;
  target_hours INTEGER;
BEGIN
  FOREACH patient_id IN ARRAY patient_ids
  LOOP
    -- Buscar horas prescritas
    SELECT prescription_hours INTO target_hours FROM patients WHERE id = patient_id;
    
    -- Gerar compliance dos últimos 7 dias
    FOR i IN 0..6 LOOP
      INSERT INTO daily_compliance (
        patient_id, date,
        prescribed_hours, actual_hours, compliance_percent,
        sessions_count, avg_session_duration,
        created_at, updated_at
      )
      VALUES (
        patient_id,
        (NOW() - (i * INTERVAL '1 day'))::DATE,
        target_hours,
        (target_hours * (0.7 + RANDOM() * 0.3))::NUMERIC(5,2),  -- 70-100% do target
        ((0.7 + RANDOM() * 0.3) * 100)::NUMERIC(5,2),
        (2 + RANDOM() * 3)::INTEGER,  -- 2-5 sessões
        ((target_hours * 3600) / (2 + RANDOM() * 3))::INTEGER,  -- duração média
        NOW() - (i * INTERVAL '1 day'),
        NOW() - (i * INTERVAL '1 day')
      )
      ON CONFLICT (patient_id, date) DO NOTHING;
    END LOOP;
  END LOOP;
END $$;

-- ============================================
-- 8. ALERTAS
-- ============================================
INSERT INTO alerts (
  type, severity, title, message,
  brace_id, patient_id,
  status, metadata,
  created_at, updated_at
)
VALUES 
  -- Alerta crítico: Bateria baixa
  (
    'battery_low', 'critical', 'Bateria Crítica',
    'Dispositivo ESP32-DEMO-003 com bateria em 15%',
    3, 3,
    'open', '{"battery_level": 15, "threshold": 20}'::jsonb,
    NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '30 minutes'
  ),
  
  -- Alerta alto: Baixo compliance
  (
    'compliance_low', 'high', 'Compliance Abaixo do Esperado',
    'Paciente Pedro Santos com apenas 65% de compliance nos últimos 3 dias',
    3, 3,
    'open', '{"compliance_percent": 65, "target": 85}'::jsonb,
    NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours'
  ),
  
  -- Alerta médio: Dispositivo offline
  (
    'device_offline', 'warning', 'Dispositivo Offline',
    'ESP32-DEMO-003 não envia dados há 2 horas',
    3, 3,
    'open', '{"last_seen": "2 hours ago"}'::jsonb,
    NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours'
  ),
  
  -- Alerta resolvido: Manutenção concluída
  (
    'maintenance_completed', 'info', 'Manutenção Concluída',
    'Dispositivo ESP32-DEMO-005 retornou da manutenção',
    5, 5,
    'resolved', '{"maintenance_type": "calibration"}'::jsonb,
    NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'
  );

-- ============================================
-- VERIFICAÇÃO FINAL
-- ============================================
SELECT 
  'Instituições' as tabela, COUNT(*) as registros FROM institutions
UNION ALL
SELECT 'Profissionais', COUNT(*) FROM medical_staff
UNION ALL
SELECT 'Pacientes', COUNT(*) FROM patients
UNION ALL
SELECT 'Dispositivos', COUNT(*) FROM braces
UNION ALL
SELECT 'Leituras Sensores', COUNT(*) FROM sensor_readings
UNION ALL
SELECT 'Sessões de Uso', COUNT(*) FROM usage_sessions
UNION ALL
SELECT 'Compliance Diário', COUNT(*) FROM daily_compliance
UNION ALL
SELECT 'Alertas', COUNT(*) FROM alerts;

-- Mostrar resumo
SELECT 
  '✓ Dados de demonstração inseridos com sucesso!' as status;
