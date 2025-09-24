package models

import (
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func TestNewAdminAction(t *testing.T) {
	adminUserID := uuid.New()
	targetID := uuid.New()
	description := "Test action"
	metadata := JSONMetadata{"key": "value"}

	action := NewAdminAction(
		adminUserID,
		ActionTypeUserCreated,
		TargetTypeUser,
		&targetID,
		description,
		metadata,
	)

	assert.NotEqual(t, uuid.Nil, action.ID)
	assert.Equal(t, adminUserID, action.AdminUserID)
	assert.Equal(t, ActionTypeUserCreated, action.ActionType)
	assert.Equal(t, TargetTypeUser, action.TargetType)
	assert.Equal(t, &targetID, action.TargetID)
	assert.Equal(t, description, action.Description)
	assert.Equal(t, metadata, action.Metadata)
	assert.NotZero(t, action.CreatedAt)
}

func TestAdminAction_Validate(t *testing.T) {
	tests := []struct {
		name    string
		action  *AdminAction
		wantErr bool
	}{
		{
			name: "valid action",
			action: &AdminAction{
				ID:          uuid.New(),
				AdminUserID: uuid.New(),
				ActionType:  ActionTypeUserCreated,
				TargetType:  TargetTypeUser,
				Description: "Test action",
			},
			wantErr: false,
		},
		{
			name: "missing admin user ID",
			action: &AdminAction{
				ID:          uuid.New(),
				AdminUserID: uuid.Nil,
				ActionType:  ActionTypeUserCreated,
				TargetType:  TargetTypeUser,
				Description: "Test action",
			},
			wantErr: true,
		},
		{
			name: "missing action type",
			action: &AdminAction{
				ID:          uuid.New(),
				AdminUserID: uuid.New(),
				ActionType:  "",
				TargetType:  TargetTypeUser,
				Description: "Test action",
			},
			wantErr: true,
		},
		{
			name: "missing target type",
			action: &AdminAction{
				ID:          uuid.New(),
				AdminUserID: uuid.New(),
				ActionType:  ActionTypeUserCreated,
				TargetType:  "",
				Description: "Test action",
			},
			wantErr: true,
		},
		{
			name: "missing description",
			action: &AdminAction{
				ID:          uuid.New(),
				AdminUserID: uuid.New(),
				ActionType:  ActionTypeUserCreated,
				TargetType:  TargetTypeUser,
				Description: "",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.action.Validate()
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestIsValidActionType(t *testing.T) {
	tests := []struct {
		actionType AdminActionType
		want       bool
	}{
		{ActionTypeUserCreated, true},
		{ActionTypeUserUpdated, true},
		{ActionTypeUserDeleted, true},
		{ActionTypeContentApproved, true},
		{ActionTypeContentRejected, true},
		{AdminActionType("invalid"), false},
		{AdminActionType(""), false},
	}

	for _, tt := range tests {
		t.Run(string(tt.actionType), func(t *testing.T) {
			assert.Equal(t, tt.want, IsValidActionType(tt.actionType))
		})
	}
}

func TestIsValidTargetType(t *testing.T) {
	tests := []struct {
		targetType TargetType
		want       bool
	}{
		{TargetTypeUser, true},
		{TargetTypeContent, true},
		{TargetTypeComment, true},
		{TargetTypePayment, true},
		{TargetTypeSystem, true},
		{TargetType("invalid"), false},
		{TargetType(""), false},
	}

	for _, tt := range tests {
		t.Run(string(tt.targetType), func(t *testing.T) {
			assert.Equal(t, tt.want, IsValidTargetType(tt.targetType))
		})
	}
}
