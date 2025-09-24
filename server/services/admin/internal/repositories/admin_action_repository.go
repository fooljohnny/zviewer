package repositories

import (
	"database/sql"
	"fmt"
	"time"

	"zviewer-admin-service/internal/models"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

// AdminActionRepository handles admin action data operations
type AdminActionRepository struct {
	db *sql.DB
}

// NewAdminActionRepository creates a new admin action repository
func NewAdminActionRepository(db *sql.DB) *AdminActionRepository {
	return &AdminActionRepository{db: db}
}

// Create creates a new admin action
func (r *AdminActionRepository) Create(action *models.AdminAction) error {
	query := `
		INSERT INTO admin_actions (id, admin_user_id, action_type, target_type, target_id, description, metadata, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`

	_, err := r.db.Exec(query,
		action.ID,
		action.AdminUserID,
		action.ActionType,
		action.TargetType,
		action.TargetID,
		action.Description,
		action.Metadata,
		action.CreatedAt,
	)

	if err != nil {
		logrus.WithError(err).Error("Failed to create admin action")
		return fmt.Errorf("failed to create admin action: %w", err)
	}

	return nil
}

// GetByID retrieves an admin action by ID
func (r *AdminActionRepository) GetByID(id uuid.UUID) (*models.AdminAction, error) {
	query := `
		SELECT id, admin_user_id, action_type, target_type, target_id, description, metadata, created_at
		FROM admin_actions
		WHERE id = $1
	`

	action := &models.AdminAction{}
	err := r.db.QueryRow(query, id).Scan(
		&action.ID,
		&action.AdminUserID,
		&action.ActionType,
		&action.TargetType,
		&action.TargetID,
		&action.Description,
		&action.Metadata,
		&action.CreatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("admin action not found")
		}
		logrus.WithError(err).Error("Failed to get admin action by ID")
		return nil, fmt.Errorf("failed to get admin action: %w", err)
	}

	return action, nil
}

// List retrieves admin actions with pagination and filtering
func (r *AdminActionRepository) List(offset, limit int, filters map[string]interface{}) ([]*models.AdminAction, int, error) {
	// Build WHERE clause
	whereClause := "WHERE 1=1"
	args := []interface{}{}
	argIndex := 1

	if adminUserID, ok := filters["admin_user_id"].(uuid.UUID); ok {
		whereClause += fmt.Sprintf(" AND admin_user_id = $%d", argIndex)
		args = append(args, adminUserID)
		argIndex++
	}

	if actionType, ok := filters["action_type"].(string); ok {
		whereClause += fmt.Sprintf(" AND action_type = $%d", argIndex)
		args = append(args, actionType)
		argIndex++
	}

	if targetType, ok := filters["target_type"].(string); ok {
		whereClause += fmt.Sprintf(" AND target_type = $%d", argIndex)
		args = append(args, targetType)
		argIndex++
	}

	if targetID, ok := filters["target_id"].(uuid.UUID); ok {
		whereClause += fmt.Sprintf(" AND target_id = $%d", argIndex)
		args = append(args, targetID)
		argIndex++
	}

	if startDate, ok := filters["start_date"].(time.Time); ok {
		whereClause += fmt.Sprintf(" AND created_at >= $%d", argIndex)
		args = append(args, startDate)
		argIndex++
	}

	if endDate, ok := filters["end_date"].(time.Time); ok {
		whereClause += fmt.Sprintf(" AND created_at <= $%d", argIndex)
		args = append(args, endDate)
		argIndex++
	}

	// Count total records
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM admin_actions %s", whereClause)
	var total int
	err := r.db.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		logrus.WithError(err).Error("Failed to count admin actions")
		return nil, 0, fmt.Errorf("failed to count admin actions: %w", err)
	}

	// Get paginated results
	query := fmt.Sprintf(`
		SELECT id, admin_user_id, action_type, target_type, target_id, description, metadata, created_at
		FROM admin_actions
		%s
		ORDER BY created_at DESC
		OFFSET $%d LIMIT $%d
	`, whereClause, argIndex, argIndex+1)

	args = append(args, offset, limit)

	rows, err := r.db.Query(query, args...)
	if err != nil {
		logrus.WithError(err).Error("Failed to list admin actions")
		return nil, 0, fmt.Errorf("failed to list admin actions: %w", err)
	}
	defer rows.Close()

	var actions []*models.AdminAction
	for rows.Next() {
		action := &models.AdminAction{}
		err := rows.Scan(
			&action.ID,
			&action.AdminUserID,
			&action.ActionType,
			&action.TargetType,
			&action.TargetID,
			&action.Description,
			&action.Metadata,
			&action.CreatedAt,
		)
		if err != nil {
			logrus.WithError(err).Error("Failed to scan admin action")
			return nil, 0, fmt.Errorf("failed to scan admin action: %w", err)
		}
		actions = append(actions, action)
	}

	return actions, total, nil
}

// GetByTargetID retrieves admin actions for a specific target
func (r *AdminActionRepository) GetByTargetID(targetType string, targetID uuid.UUID) ([]*models.AdminAction, error) {
	query := `
		SELECT id, admin_user_id, action_type, target_type, target_id, description, metadata, created_at
		FROM admin_actions
		WHERE target_type = $1 AND target_id = $2
		ORDER BY created_at DESC
	`

	rows, err := r.db.Query(query, targetType, targetID)
	if err != nil {
		logrus.WithError(err).Error("Failed to get admin actions by target ID")
		return nil, fmt.Errorf("failed to get admin actions by target ID: %w", err)
	}
	defer rows.Close()

	var actions []*models.AdminAction
	for rows.Next() {
		action := &models.AdminAction{}
		err := rows.Scan(
			&action.ID,
			&action.AdminUserID,
			&action.ActionType,
			&action.TargetType,
			&action.TargetID,
			&action.Description,
			&action.Metadata,
			&action.CreatedAt,
		)
		if err != nil {
			logrus.WithError(err).Error("Failed to scan admin action")
			return nil, fmt.Errorf("failed to scan admin action: %w", err)
		}
		actions = append(actions, action)
	}

	return actions, nil
}

// Delete deletes an admin action
func (r *AdminActionRepository) Delete(id uuid.UUID) error {
	query := "DELETE FROM admin_actions WHERE id = $1"

	result, err := r.db.Exec(query, id)
	if err != nil {
		logrus.WithError(err).Error("Failed to delete admin action")
		return fmt.Errorf("failed to delete admin action: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("admin action not found")
	}

	return nil
}
