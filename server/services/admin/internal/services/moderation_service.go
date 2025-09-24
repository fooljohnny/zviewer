package services

import (
	"fmt"

	"zviewer-admin-service/internal/models"
	"zviewer-admin-service/internal/repositories"

	"github.com/google/uuid"
)

// ModerationService handles moderation business logic
type ModerationService struct {
	contentModerationRepo *repositories.ContentModerationRepository
	adminActionRepo       *repositories.AdminActionRepository
}

// NewModerationService creates a new moderation service
func NewModerationService(contentModerationRepo *repositories.ContentModerationRepository, adminActionRepo *repositories.AdminActionRepository) *ModerationService {
	return &ModerationService{
		contentModerationRepo: contentModerationRepo,
		adminActionRepo:       adminActionRepo,
	}
}

// GetModerationQueue retrieves content pending moderation
func (s *ModerationService) GetModerationQueue(page, limit int) ([]*models.ContentModeration, int, error) {
	offset := (page - 1) * limit
	return s.contentModerationRepo.GetModerationQueue(offset, limit)
}

// SubmitModerationDecision submits a moderation decision
func (s *ModerationService) SubmitModerationDecision(contentID uuid.UUID, moderatorID uuid.UUID, status string, reason string, reviewNotes string) error {
	// Get existing moderation record
	moderation, err := s.contentModerationRepo.GetByContentID(contentID)
	if err != nil {
		return fmt.Errorf("failed to get content moderation: %w", err)
	}

	// Update moderation record
	moderationStatus := models.ModerationStatus(status)
	moderation.UpdateStatus(moderationStatus, &moderatorID, reason, reviewNotes)

	if err := s.contentModerationRepo.Update(moderation); err != nil {
		return fmt.Errorf("failed to update content moderation: %w", err)
	}

	// Log admin action
	var actionType models.AdminActionType
	switch moderationStatus {
	case models.ModerationStatusApproved:
		actionType = models.ActionTypeContentApproved
	case models.ModerationStatusRejected:
		actionType = models.ActionTypeContentRejected
	case models.ModerationStatusFlagged:
		actionType = models.ActionTypeContentFlagged
	default:
		actionType = models.ActionTypeContentApproved // Default fallback
	}

	adminAction := models.NewAdminAction(
		moderatorID,
		actionType,
		models.TargetTypeContent,
		&contentID,
		fmt.Sprintf("Content moderation decision: %s", status),
		models.JSONMetadata{
			"content_id":   contentID.String(),
			"status":       status,
			"reason":       reason,
			"review_notes": reviewNotes,
		},
	)

	if err := s.adminActionRepo.Create(adminAction); err != nil {
		// Log error but don't fail the operation
		fmt.Printf("Failed to log admin action: %v\n", err)
	}

	return nil
}

// GetModerationHistory retrieves moderation history
func (s *ModerationService) GetModerationHistory(page, limit int, filters map[string]interface{}) ([]*models.ContentModeration, int, error) {
	offset := (page - 1) * limit
	return s.contentModerationRepo.List(offset, limit, filters)
}

// BulkModeration performs bulk moderation actions
func (s *ModerationService) BulkModeration(contentIDs []uuid.UUID, moderatorID uuid.UUID, status string, reason string, reviewNotes string) error {
	for _, contentID := range contentIDs {
		if err := s.SubmitModerationDecision(contentID, moderatorID, status, reason, reviewNotes); err != nil {
			// Log error but continue with other items
			fmt.Printf("Failed to moderate content %s: %v\n", contentID.String(), err)
		}
	}
	return nil
}
