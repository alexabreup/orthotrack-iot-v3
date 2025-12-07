package database

import (
	"fmt"
	"log"

	"orthotrack-iot-v3/internal/models"

	"gorm.io/gorm"
)

// AutoMigrate executa as migrações automáticas do GORM
func AutoMigrate(db *gorm.DB) error {
	log.Println("Starting database auto-migration...")

	// Order matters - migrate tables with dependencies last
	models := []interface{}{
		&models.Institution{},
		&models.MedicalStaff{},
		&models.Patient{},
		&models.Brace{},
		&models.BraceCommand{},
		&models.SensorReading{},
		&models.UsageSession{},
		&models.DailyCompliance{},
		&models.Alert{},
	}

	for _, model := range models {
		if err := db.AutoMigrate(model); err != nil {
			return fmt.Errorf("failed to migrate %T: %w", model, err)
		}
		log.Printf("Successfully migrated %T", model)
	}

	// Create indexes for better performance
	if err := createCustomIndexes(db); err != nil {
		return fmt.Errorf("failed to create custom indexes: %w", err)
	}

	// Create constraints
	if err := createConstraints(db); err != nil {
		return fmt.Errorf("failed to create constraints: %w", err)
	}

	log.Println("Database auto-migration completed successfully")
	return nil
}

// createCustomIndexes creates additional indexes for performance
func createCustomIndexes(db *gorm.DB) error {
	log.Println("Creating custom indexes...")

	indexes := []string{
		// Patient indexes
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_patients_external_id_active ON patients(external_id) WHERE deleted_at IS NULL",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_patients_institution_active ON patients(institution_id) WHERE deleted_at IS NULL AND is_active = true",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_patients_status_created ON patients(status, created_at) WHERE deleted_at IS NULL",

		// Brace indexes
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_braces_patient_status ON braces(patient_id, status) WHERE deleted_at IS NULL",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_braces_device_id_active ON braces(device_id) WHERE deleted_at IS NULL AND status != 'inactive'",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_braces_last_heartbeat ON braces(last_heartbeat DESC) WHERE deleted_at IS NULL",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_braces_battery_low ON braces(battery_level) WHERE battery_level IS NOT NULL AND battery_level < 20",

		// SensorReading indexes for time-series queries
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_sensor_readings_brace_timestamp ON sensor_readings(brace_id, timestamp DESC)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_sensor_readings_patient_timestamp ON sensor_readings(patient_id, timestamp DESC)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_sensor_readings_timestamp_day ON sensor_readings(DATE(timestamp), brace_id)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_sensor_readings_is_wearing ON sensor_readings(brace_id, is_wearing, timestamp) WHERE is_wearing = true",

		// UsageSession indexes
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_usage_sessions_patient_date ON usage_sessions(patient_id, DATE(start_time))",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_usage_sessions_active ON usage_sessions(brace_id, is_active) WHERE is_active = true",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_usage_sessions_duration ON usage_sessions(patient_id, start_time) WHERE duration IS NOT NULL",

		// DailyCompliance indexes
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_compliance_patient_date ON daily_compliance(patient_id, date DESC)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_compliance_compliance ON daily_compliance(patient_id, compliance_percent) WHERE compliance_percent IS NOT NULL",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_compliance_non_compliant ON daily_compliance(patient_id, date) WHERE is_compliant = false",

		// Alert indexes
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_alerts_patient_type_status ON alerts(patient_id, alert_type, status)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_alerts_brace_severity ON alerts(brace_id, severity, created_at DESC)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_alerts_unresolved ON alerts(created_at DESC) WHERE status IN ('open', 'acknowledged')",

		// BraceCommand indexes
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_brace_commands_status_priority ON brace_commands(brace_id, status, priority)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_brace_commands_pending ON brace_commands(created_at) WHERE status = 'pending'",
	}

	for _, indexSQL := range indexes {
		if err := db.Exec(indexSQL).Error; err != nil {
			log.Printf("Warning: Failed to create index: %v", err)
			// Continue with other indexes even if one fails
		}
	}

	log.Println("Custom indexes created successfully")
	return nil
}

// createConstraints creates foreign key constraints and check constraints
func createConstraints(db *gorm.DB) error {
	log.Println("Creating database constraints...")

	constraints := []string{
		// Check constraints
		"ALTER TABLE patients ADD CONSTRAINT chk_patients_gender CHECK (gender IN ('M', 'F'))",
		"ALTER TABLE patients ADD CONSTRAINT chk_patients_severity CHECK (severity_level BETWEEN 1 AND 5)",
		"ALTER TABLE patients ADD CONSTRAINT chk_patients_prescription_hours CHECK (prescription_hours BETWEEN 1 AND 24)",
		"ALTER TABLE patients ADD CONSTRAINT chk_patients_target_minutes CHECK (daily_usage_target_minutes BETWEEN 60 AND 1440)",

		"ALTER TABLE braces ADD CONSTRAINT chk_braces_battery CHECK (battery_level BETWEEN 0 AND 100)",
		"ALTER TABLE braces ADD CONSTRAINT chk_braces_signal CHECK (signal_strength BETWEEN -120 AND 0)",
		"ALTER TABLE braces ADD CONSTRAINT chk_braces_usage_hours CHECK (total_usage_hours >= 0)",

		"ALTER TABLE sensor_readings ADD CONSTRAINT chk_sensor_temperature CHECK (temperature BETWEEN -20 AND 60)",
		"ALTER TABLE sensor_readings ADD CONSTRAINT chk_sensor_humidity CHECK (humidity BETWEEN 0 AND 100)",
		"ALTER TABLE sensor_readings ADD CONSTRAINT chk_sensor_battery_voltage CHECK (battery_voltage BETWEEN 2.0 AND 5.0)",

		"ALTER TABLE usage_sessions ADD CONSTRAINT chk_session_scores CHECK (compliance_score BETWEEN 0 AND 100 AND comfort_score BETWEEN 0 AND 100 AND posture_score BETWEEN 0 AND 100)",
		"ALTER TABLE usage_sessions ADD CONSTRAINT chk_session_ratings CHECK (patient_rating BETWEEN 1 AND 5 AND pain_level BETWEEN 0 AND 10 AND comfort_level BETWEEN 1 AND 5)",
		"ALTER TABLE usage_sessions ADD CONSTRAINT chk_session_duration CHECK (duration IS NULL OR duration > 0)",

		"ALTER TABLE daily_compliance ADD CONSTRAINT chk_compliance_percent CHECK (compliance_percent BETWEEN 0 AND 200)", // Allow > 100% for overachievers
		"ALTER TABLE daily_compliance ADD CONSTRAINT chk_compliance_minutes CHECK (target_minutes > 0 AND actual_minutes >= 0)",
		"ALTER TABLE daily_compliance ADD CONSTRAINT chk_compliance_sessions CHECK (session_count >= 0)",

		"ALTER TABLE brace_commands ADD CONSTRAINT chk_command_retries CHECK (retry_count >= 0 AND max_retries >= 0 AND retry_count <= max_retries)",
		"ALTER TABLE brace_commands ADD CONSTRAINT chk_command_timeout CHECK (timeout_duration > 0)",
	}

	for _, constraintSQL := range constraints {
		if err := db.Exec(constraintSQL).Error; err != nil {
			// Many constraints might already exist, so we log warnings instead of failing
			log.Printf("Warning: Failed to create constraint: %v", err)
		}
	}

	log.Println("Database constraints processed")
	return nil
}

// CreatePartitions creates time-based partitions for large tables
func CreatePartitions(db *gorm.DB) error {
	log.Println("Creating table partitions...")

	// Partition sensor_readings by month for better performance
	partitionSQL := `
		-- Create partitioned table for sensor_readings if not exists
		DO $$
		BEGIN
			IF NOT EXISTS (
				SELECT 1 FROM pg_tables 
				WHERE schemaname = 'public' 
				AND tablename = 'sensor_readings_partitioned'
			) THEN
				-- Create parent table
				CREATE TABLE sensor_readings_partitioned (
					LIKE sensor_readings INCLUDING ALL
				) PARTITION BY RANGE (timestamp);

				-- Create initial partitions (current month and next 3 months)
				DECLARE
					start_date date := date_trunc('month', CURRENT_DATE);
					end_date date;
					table_name text;
					i integer;
				BEGIN
					FOR i IN 0..3 LOOP
						end_date := start_date + interval '1 month';
						table_name := 'sensor_readings_' || to_char(start_date, 'YYYY_MM');
						
						EXECUTE format(
							'CREATE TABLE %I PARTITION OF sensor_readings_partitioned 
							FOR VALUES FROM (%L) TO (%L)',
							table_name, start_date, end_date
						);
						
						start_date := end_date;
					END LOOP;
				END;
			END IF;
		END
		$$;
	`

	if err := db.Exec(partitionSQL).Error; err != nil {
		log.Printf("Warning: Failed to create partitions: %v", err)
		// Partitioning is optional, don't fail the migration
	}

	return nil
}

// SeedData inserts initial data for development/testing
func SeedData(db *gorm.DB) error {
	log.Println("Seeding initial data...")

	// Check if data already exists
	var count int64
	db.Model(&models.Institution{}).Count(&count)
	if count > 0 {
		log.Println("Data already exists, skipping seed")
		return nil
	}

	// Create AACD institution
	institution := models.Institution{
		Name:    "AACD - Associação de Assistência à Criança Deficiente",
		Code:    "AACD-SP",
		CNPJ:    "60.945.284/0001-06",
		Address: "Av. Prof. Ascendino Reis, 724 - Vila Clementino, São Paulo - SP",
		City:    "São Paulo",
		State:   "SP",
		ZipCode: "04027-000",
		Phone:   "(11) 5576-0777",
		Email:   "contato@aacd.org.br",
		Website: "https://www.aacd.org.br",
		Type:    "hospital",
		Status:  "active",
	}

	if err := db.Create(&institution).Error; err != nil {
		return fmt.Errorf("failed to seed institution: %w", err)
	}

	// Create admin medical staff
	adminStaff := models.MedicalStaff{
		InstitutionID: institution.ID,
		Name:          "Dr. Administrador Sistema",
		Email:         "admin@aacd.org.br",
		Phone:         "(11) 5576-0777",
		Role:          "admin",
		Specialty:     "Ortopedia",
		Department:    "Tecnologia",
		PasswordHash:  "$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi", // "password"
		IsActive:      true,
		Permissions:   `{"admin": true, "patients": ["read", "write"], "devices": ["read", "write"], "reports": ["read", "write"]}`,
	}

	if err := db.Create(&adminStaff).Error; err != nil {
		return fmt.Errorf("failed to seed admin staff: %w", err)
	}

	log.Printf("Seeded institution: %s (ID: %d)", institution.Name, institution.ID)
	log.Printf("Seeded admin user: %s (ID: %d)", adminStaff.Email, adminStaff.ID)
	log.Println("Initial data seeded successfully")

	return nil
}

// DropAllTables drops all tables (useful for development reset)
func DropAllTables(db *gorm.DB) error {
	log.Println("WARNING: Dropping all tables...")

	tables := []string{
		"alerts",
		"daily_compliance", 
		"usage_sessions",
		"sensor_readings",
		"brace_commands",
		"braces",
		"patients",
		"medical_staff",
		"institutions",
	}

	for _, table := range tables {
		if err := db.Exec(fmt.Sprintf("DROP TABLE IF EXISTS %s CASCADE", table)).Error; err != nil {
			log.Printf("Failed to drop table %s: %v", table, err)
		} else {
			log.Printf("Dropped table: %s", table)
		}
	}

	log.Println("All tables dropped")
	return nil
}

// GetMigrationStatus returns the current migration status
func GetMigrationStatus(db *gorm.DB) (map[string]bool, error) {
	status := make(map[string]bool)

	tables := []string{
		"institutions",
		"medical_staff",
		"patients",
		"braces",
		"brace_commands",
		"sensor_readings",
		"usage_sessions",
		"daily_compliance",
		"alerts",
	}

	for _, table := range tables {
		var exists bool
		err := db.Raw("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = ?)", table).Scan(&exists).Error
		if err != nil {
			return nil, err
		}
		status[table] = exists
	}

	return status, nil
}