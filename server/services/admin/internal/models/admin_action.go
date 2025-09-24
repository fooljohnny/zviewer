package models

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// AdminActionType represents the type of admin action
type AdminActionType string

const (
	ActionTypeUserCreated         AdminActionType = "user_created"
	ActionTypeUserUpdated         AdminActionType = "user_updated"
	ActionTypeUserDeleted         AdminActionType = "user_deleted"
	ActionTypeUserRoleChanged     AdminActionType = "user_role_changed"
	ActionTypeUserStatusChanged   AdminActionType = "user_status_changed"
	ActionTypeContentApproved     AdminActionType = "content_approved"
	ActionTypeContentRejected     AdminActionType = "content_rejected"
	ActionTypeContentFlagged      AdminActionType = "content_flagged"
	ActionTypeContentDeleted      AdminActionType = "content_deleted"
	ActionTypeCommentDeleted      AdminActionType = "comment_deleted"
	ActionTypePaymentRefunded     AdminActionType = "payment_refunded"
	ActionTypeSystemConfigChanged AdminActionType = "system_config_changed"
)

// TargetType represents the type of target entity
type TargetType string

const (
	TargetTypeUser    TargetType = "user"
	TargetTypeContent TargetType = "content"
	TargetTypeComment TargetType = "comment"
	TargetTypePayment TargetType = "payment"
	TargetTypeSystem  TargetType = "system"
)

// AdminAction represents an administrative action taken by an admin user
type AdminAction struct {
	ID          uuid.UUID       `json:"id" db:"id"`
	AdminUserID uuid.UUID       `json:"admin_user_id" db:"admin_user_id"`
	ActionType  AdminActionType `json:"action_type" db:"action_type"`
	TargetType  TargetType      `json:"target_type" db:"target_type"`
	TargetID    *uuid.UUID      `json:"target_id" db:"target_id"`
	Description string          `json:"description" db:"description"`
	Metadata    JSONMetadata    `json:"metadata" db:"metadata"`
	CreatedAt   time.Time       `json:"created_at" db:"created_at"`
}

// JSONMetadata represents JSON metadata that can be stored in the database
type JSONMetadata map[string]interface{}

// Value implements the driver.Valuer interface for database storage
func (j JSONMetadata) Value() (driver.Value, error) {
	if j == nil {
		return nil, nil
	}
	return json.Marshal(j)
}

// Scan implements the sql.Scanner interface for database retrieval
func (j *JSONMetadata) Scan(value interface{}) error {
	if value == nil {
		*j = nil
		return nil
	}

	bytes, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("cannot scan %T into JSONMetadata", value)
	}

	return json.Unmarshal(bytes, j)
}

// NewAdminAction creates a new AdminAction instance
func NewAdminAction(adminUserID uuid.UUID, actionType AdminActionType, targetType TargetType, targetID *uuid.UUID, description string, metadata JSONMetadata) *AdminAction {
	return &AdminAction{
		ID:          uuid.New(),
		AdminUserID: adminUserID,
		ActionType:  actionType,
		TargetType:  targetType,
		TargetID:    targetID,
		Description: description,
		Metadata:    metadata,
		CreatedAt:   time.Now(),
	}
}

// Validate validates the AdminAction fields
func (a *AdminAction) Validate() error {
	if a.AdminUserID == uuid.Nil {
		return fmt.Errorf("admin_user_id is required")
	}
	if a.ActionType == "" {
		return fmt.Errorf("action_type is required")
	}
	if a.TargetType == "" {
		return fmt.Errorf("target_type is required")
	}
	if a.Description == "" {
		return fmt.Errorf("description is required")
	}
	return nil
}

// IsValidActionType checks if the action type is valid
func IsValidActionType(actionType AdminActionType) bool {
	validTypes := []AdminActionType{
		ActionTypeUserCreated,
		ActionTypeUserUpdated,
		ActionTypeUserDeleted,
		ActionTypeUserRoleChanged,
		ActionTypeUserStatusChanged,
		ActionTypeContentApproved,
		ActionTypeContentRejected,
		ActionTypeContentFlagged,
		ActionTypeContentDeleted,
		ActionTypeCommentDeleted,
		ActionTypePaymentRefunded,
		ActionTypeSystemConfigChanged,
	}

	for _, validType := range validTypes {
		if actionType == validType {
			return true
		}
	}
	return false
}

// IsValidTargetType checks if the target type is valid
func IsValidTargetType(targetType TargetType) bool {
	validTypes := []TargetType{
		TargetTypeUser,
		TargetTypeContent,
		TargetTypeComment,
		TargetTypePayment,
		TargetTypeSystem,
	}

	for _, validType := range validTypes {
		if targetType == validType {
			return true
		}
	}
	return false
}
