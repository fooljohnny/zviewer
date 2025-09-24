package models

import (
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func TestNewContentModeration(t *testing.T) {
	contentID := uuid.New()
	moderatorID := uuid.New()
	status := ModerationStatusPending
	reason := "Test reason"
	flags := FlagTypes{FlagTypeInappropriate, FlagTypeSpam}
	reviewNotes := "Test notes"

	moderation := NewContentModeration(
		contentID,
		&moderatorID,
		status,
		reason,
		flags,
		reviewNotes,
	)

	assert.NotEqual(t, uuid.Nil, moderation.ID)
	assert.Equal(t, contentID, moderation.ContentID)
	assert.Equal(t, &moderatorID, moderation.ModeratorID)
	assert.Equal(t, status, moderation.Status)
	assert.Equal(t, reason, moderation.Reason)
	assert.Equal(t, flags, moderation.Flags)
	assert.Equal(t, reviewNotes, moderation.ReviewNotes)
	assert.NotZero(t, moderation.CreatedAt)
	assert.NotZero(t, moderation.UpdatedAt)
}

func TestContentModeration_Validate(t *testing.T) {
	tests := []struct {
		name       string
		moderation *ContentModeration
		wantErr    bool
	}{
		{
			name: "valid moderation",
			moderation: &ContentModeration{
				ID:        uuid.New(),
				ContentID: uuid.New(),
				Status:    ModerationStatusPending,
				Reason:    "Test reason",
				Flags:     FlagTypes{FlagTypeInappropriate},
			},
			wantErr: false,
		},
		{
			name: "missing content ID",
			moderation: &ContentModeration{
				ID:        uuid.New(),
				ContentID: uuid.Nil,
				Status:    ModerationStatusPending,
				Reason:    "Test reason",
				Flags:     FlagTypes{FlagTypeInappropriate},
			},
			wantErr: true,
		},
		{
			name: "missing status",
			moderation: &ContentModeration{
				ID:        uuid.New(),
				ContentID: uuid.New(),
				Status:    "",
				Reason:    "Test reason",
				Flags:     FlagTypes{FlagTypeInappropriate},
			},
			wantErr: true,
		},
		{
			name: "invalid status",
			moderation: &ContentModeration{
				ID:        uuid.New(),
				ContentID: uuid.New(),
				Status:    ModerationStatus("invalid"),
				Reason:    "Test reason",
				Flags:     FlagTypes{FlagTypeInappropriate},
			},
			wantErr: true,
		},
		{
			name: "rejected without reason",
			moderation: &ContentModeration{
				ID:        uuid.New(),
				ContentID: uuid.New(),
				Status:    ModerationStatusRejected,
				Reason:    "",
				Flags:     FlagTypes{FlagTypeInappropriate},
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.moderation.Validate()
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestContentModeration_AddFlag(t *testing.T) {
	moderation := &ContentModeration{
		Flags: FlagTypes{FlagTypeInappropriate},
	}

	// Add new flag
	moderation.AddFlag(FlagTypeSpam)
	assert.Contains(t, moderation.Flags, FlagTypeSpam)
	assert.Contains(t, moderation.Flags, FlagTypeInappropriate)

	// Add existing flag (should not duplicate)
	originalLength := len(moderation.Flags)
	moderation.AddFlag(FlagTypeSpam)
	assert.Len(t, moderation.Flags, originalLength)
}

func TestContentModeration_RemoveFlag(t *testing.T) {
	moderation := &ContentModeration{
		Flags: FlagTypes{FlagTypeInappropriate, FlagTypeSpam},
	}

	// Remove existing flag
	moderation.RemoveFlag(FlagTypeSpam)
	assert.NotContains(t, moderation.Flags, FlagTypeSpam)
	assert.Contains(t, moderation.Flags, FlagTypeInappropriate)

	// Remove non-existing flag (should not error)
	originalLength := len(moderation.Flags)
	moderation.RemoveFlag(FlagTypeCopyright)
	assert.Len(t, moderation.Flags, originalLength)
}

func TestContentModeration_HasFlag(t *testing.T) {
	moderation := &ContentModeration{
		Flags: FlagTypes{FlagTypeInappropriate, FlagTypeSpam},
	}

	assert.True(t, moderation.HasFlag(FlagTypeInappropriate))
	assert.True(t, moderation.HasFlag(FlagTypeSpam))
	assert.False(t, moderation.HasFlag(FlagTypeCopyright))
}

func TestIsValidModerationStatus(t *testing.T) {
	tests := []struct {
		status ModerationStatus
		want   bool
	}{
		{ModerationStatusPending, true},
		{ModerationStatusApproved, true},
		{ModerationStatusRejected, true},
		{ModerationStatusFlagged, true},
		{ModerationStatus("invalid"), false},
		{ModerationStatus(""), false},
	}

	for _, tt := range tests {
		t.Run(string(tt.status), func(t *testing.T) {
			assert.Equal(t, tt.want, IsValidModerationStatus(tt.status))
		})
	}
}

func TestIsValidFlagType(t *testing.T) {
	tests := []struct {
		flagType FlagType
		want     bool
	}{
		{FlagTypeInappropriate, true},
		{FlagTypeSpam, true},
		{FlagTypeCopyright, true},
		{FlagTypeViolence, true},
		{FlagTypeNudity, true},
		{FlagTypeHateSpeech, true},
		{FlagTypeHarassment, true},
		{FlagTypeOther, true},
		{FlagType("invalid"), false},
		{FlagType(""), false},
	}

	for _, tt := range tests {
		t.Run(string(tt.flagType), func(t *testing.T) {
			assert.Equal(t, tt.want, IsValidFlagType(tt.flagType))
		})
	}
}
