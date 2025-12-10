package services

import (
	"context"
	"fmt"
	"strconv"
	"strings"

	"gorm.io/gorm"
)

// ChannelAuthorizer handles authorization for WebSocket channel subscriptions
type ChannelAuthorizer struct {
	db *gorm.DB
}

// NewChannelAuthorizer creates a new channel authorizer
func NewChannelAuthorizer(db *gorm.DB) *ChannelAuthorizer {
	return &ChannelAuthorizer{
		db: db,
	}
}

// CanSubscribe checks if a user can subscribe to a specific channel
func (ca *ChannelAuthorizer) CanSubscribe(ctx context.Context, userID, institutionID, role, channel string) error {
	// Parse channel format: type:id (e.g., "patient:123", "device:456", "dashboard")
	parts := strings.Split(channel, ":")
	if len(parts) == 0 {
		return fmt.Errorf("invalid channel format")
	}

	channelType := parts[0]

	switch channelType {
	case "dashboard":
		// Dashboard channel - all authenticated users can subscribe
		return nil

	case "alerts":
		// Global alerts channel
		if len(parts) == 2 && parts[1] == "global" {
			// All authenticated users can subscribe to global alerts
			return nil
		}
		return fmt.Errorf("invalid alerts channel format")

	case "patient":
		// Patient channel - verify user has access to this patient
		if len(parts) != 2 {
			return fmt.Errorf("invalid patient channel format")
		}
		patientID := parts[1]
		return ca.canAccessPatient(ctx, userID, institutionID, role, patientID)

	case "device":
		// Device channel - verify user has access to the device's patient
		if len(parts) != 2 {
			return fmt.Errorf("invalid device channel format")
		}
		deviceID := parts[1]
		return ca.canAccessDevice(ctx, userID, institutionID, role, deviceID)

	default:
		return fmt.Errorf("unknown channel type: %s", channelType)
	}
}

// canAccessPatient checks if user can access a specific patient
func (ca *ChannelAuthorizer) canAccessPatient(ctx context.Context, userID, institutionID, role, patientID string) error {
	// Convert IDs to uint
	userIDUint, err := strconv.ParseUint(userID, 10, 32)
	if err != nil {
		return fmt.Errorf("invalid user ID")
	}

	institutionIDUint, err := strconv.ParseUint(institutionID, 10, 32)
	if err != nil {
		return fmt.Errorf("invalid institution ID")
	}

	patientIDUint, err := strconv.ParseUint(patientID, 10, 32)
	if err != nil {
		return fmt.Errorf("invalid patient ID")
	}

	// Check if patient exists and belongs to user's institution
	var count int64
	query := ca.db.WithContext(ctx).
		Table("patients").
		Where("id = ? AND institution_id = ?", patientIDUint, institutionIDUint)

	// If user is a medical staff member (not admin), also check if they're assigned to this patient
	if role != "admin" && role != "administrator" {
		query = query.Where("medical_staff_id = ? OR medical_staff_id IS NULL", userIDUint)
	}

	err = query.Count(&count).Error
	if err != nil {
		return fmt.Errorf("database error: %w", err)
	}

	if count == 0 {
		return fmt.Errorf("access denied: patient not found or not accessible")
	}

	return nil
}

// canAccessDevice checks if user can access a specific device
func (ca *ChannelAuthorizer) canAccessDevice(ctx context.Context, userID, institutionID, role, deviceID string) error {
	// Convert IDs to uint
	userIDUint, err := strconv.ParseUint(userID, 10, 32)
	if err != nil {
		return fmt.Errorf("invalid user ID")
	}

	institutionIDUint, err := strconv.ParseUint(institutionID, 10, 32)
	if err != nil {
		return fmt.Errorf("invalid institution ID")
	}

	// Check if device exists and its patient belongs to user's institution
	var count int64
	query := ca.db.WithContext(ctx).
		Table("braces").
		Joins("LEFT JOIN patients ON braces.patient_id = patients.id").
		Where("braces.device_id = ?", deviceID)

	// Device must either be unassigned or belong to a patient in user's institution
	query = query.Where("patients.institution_id = ? OR braces.patient_id IS NULL", institutionIDUint)

	// If user is a medical staff member (not admin), also check patient assignment
	if role != "admin" && role != "administrator" {
		query = query.Where("patients.medical_staff_id = ? OR patients.medical_staff_id IS NULL OR braces.patient_id IS NULL", userIDUint)
	}

	err = query.Count(&count).Error
	if err != nil {
		return fmt.Errorf("database error: %w", err)
	}

	if count == 0 {
		return fmt.Errorf("access denied: device not found or not accessible")
	}

	return nil
}

// ValidateChannelFormat validates the channel format without checking permissions
func ValidateChannelFormat(channel string) error {
	parts := strings.Split(channel, ":")
	if len(parts) == 0 {
		return fmt.Errorf("invalid channel format")
	}

	channelType := parts[0]

	switch channelType {
	case "dashboard":
		if len(parts) != 1 {
			return fmt.Errorf("dashboard channel should not have additional parts")
		}
		return nil

	case "alerts":
		if len(parts) != 2 || parts[1] != "global" {
			return fmt.Errorf("alerts channel must be 'alerts:global'")
		}
		return nil

	case "patient":
		if len(parts) != 2 {
			return fmt.Errorf("patient channel must be 'patient:id'")
		}
		// Validate ID is numeric
		if _, err := strconv.ParseUint(parts[1], 10, 32); err != nil {
			return fmt.Errorf("patient ID must be numeric")
		}
		return nil

	case "device":
		if len(parts) != 2 {
			return fmt.Errorf("device channel must be 'device:id'")
		}
		// Device ID can be alphanumeric (device_id from braces table)
		if parts[1] == "" {
			return fmt.Errorf("device ID cannot be empty")
		}
		return nil

	default:
		return fmt.Errorf("unknown channel type: %s", channelType)
	}
}
