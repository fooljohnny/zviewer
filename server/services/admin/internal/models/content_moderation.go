package models

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// ModerationStatus represents the status of content moderation
type ModerationStatus string

const (
	ModerationStatusPending  ModerationStatus = "pending"
	ModerationStatusApproved ModerationStatus = "approved"
	ModerationStatusRejected ModerationStatus = "rejected"
	ModerationStatusFlagged  ModerationStatus = "flagged"
)

// FlagType represents the type of content flag
type FlagType string

const (
	FlagTypeInappropriate FlagType = "inappropriate"
	FlagTypeSpam          FlagType = "spam"
	FlagTypeCopyright     FlagType = "copyright"
	FlagTypeViolence      FlagType = "violence"
	FlagTypeNudity        FlagType = "nudity"
	FlagTypeHateSpeech    FlagType = "hate_speech"
	FlagTypeHarassment    FlagType = "harassment"
	FlagTypeOther         FlagType = "other"
)

// FlagTypes represents a slice of flag types
type FlagTypes []FlagType

// Value implements the driver.Valuer interface for database storage
func (f FlagTypes) Value() (driver.Value, error) {
	if f == nil {
		return nil, nil
	}
	return json.Marshal(f)
}

// Scan implements the sql.Scanner interface for database retrieval
func (f *FlagTypes) Scan(value interface{}) error {
	if value == nil {
		*f = nil
		return nil
	}

	bytes, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("cannot scan %T into FlagTypes", value)
	}

	return json.Unmarshal(bytes, f)
}

// ContentModeration represents content moderation information
type ContentModeration struct {
	ID          uuid.UUID        `json:"id" db:"id"`
	ContentID   uuid.UUID        `json:"content_id" db:"content_id"`
	ModeratorID *uuid.UUID       `json:"moderator_id" db:"moderator_id"`
	Status      ModerationStatus `json:"status" db:"status"`
	Reason      string           `json:"reason" db:"reason"`
	Flags       FlagTypes        `json:"flags" db:"flags"`
	ReviewNotes string           `json:"review_notes" db:"review_notes"`
	CreatedAt   time.Time        `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time        `json:"updated_at" db:"updated_at"`
}

// NewContentModeration creates a new ContentModeration instance
func NewContentModeration(contentID uuid.UUID, moderatorID *uuid.UUID, status ModerationStatus, reason string, flags FlagTypes, reviewNotes string) *ContentModeration {
	now := time.Now()
	return &ContentModeration{
		ID:          uuid.New(),
		ContentID:   contentID,
		ModeratorID: moderatorID,
		Status:      status,
		Reason:      reason,
		Flags:       flags,
		ReviewNotes: reviewNotes,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
}

// Validate validates the ContentModeration fields
func (c *ContentModeration) Validate() error {
	if c.ContentID == uuid.Nil {
		return fmt.Errorf("content_id is required")
	}
	if c.Status == "" {
		return fmt.Errorf("status is required")
	}
	if !IsValidModerationStatus(c.Status) {
		return fmt.Errorf("invalid moderation status: %s", c.Status)
	}
	if c.Status == ModerationStatusRejected && c.Reason == "" {
		return fmt.Errorf("reason is required for rejected content")
	}
	return nil
}

// UpdateStatus updates the moderation status and related fields
func (c *ContentModeration) UpdateStatus(status ModerationStatus, moderatorID *uuid.UUID, reason string, reviewNotes string) {
	c.Status = status
	c.ModeratorID = moderatorID
	c.Reason = reason
	c.ReviewNotes = reviewNotes
	c.UpdatedAt = time.Now()
}

// AddFlag adds a flag to the content moderation
func (c *ContentModeration) AddFlag(flag FlagType) {
	if !c.HasFlag(flag) {
		c.Flags = append(c.Flags, flag)
	}
}

// RemoveFlag removes a flag from the content moderation
func (c *ContentModeration) RemoveFlag(flag FlagType) {
	for i, f := range c.Flags {
		if f == flag {
			c.Flags = append(c.Flags[:i], c.Flags[i+1:]...)
			break
		}
	}
}

// HasFlag checks if the content has a specific flag
func (c *ContentModeration) HasFlag(flag FlagType) bool {
	for _, f := range c.Flags {
		if f == flag {
			return true
		}
	}
	return false
}

// IsValidModerationStatus checks if the moderation status is valid
func IsValidModerationStatus(status ModerationStatus) bool {
	validStatuses := []ModerationStatus{
		ModerationStatusPending,
		ModerationStatusApproved,
		ModerationStatusRejected,
		ModerationStatusFlagged,
	}

	for _, validStatus := range validStatuses {
		if status == validStatus {
			return true
		}
	}
	return false
}

// IsValidFlagType checks if the flag type is valid
func IsValidFlagType(flagType FlagType) bool {
	validFlags := []FlagType{
		FlagTypeInappropriate,
		FlagTypeSpam,
		FlagTypeCopyright,
		FlagTypeViolence,
		FlagTypeNudity,
		FlagTypeHateSpeech,
		FlagTypeHarassment,
		FlagTypeOther,
	}

	for _, validFlag := range validFlags {
		if flagType == validFlag {
			return true
		}
	}
	return false
}
