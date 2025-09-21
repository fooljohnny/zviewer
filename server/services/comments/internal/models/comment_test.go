package models

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func TestComment_Validate(t *testing.T) {
	tests := []struct {
		name    string
		comment Comment
		wantErr bool
	}{
		{
			name: "valid comment",
			comment: Comment{
				ID:          uuid.New().String(),
				UserID:      uuid.New().String(),
				MediaItemID: uuid.New().String(),
				Content:     "This is a valid comment",
				Status:      CommentStatusActive,
			},
			wantErr: false,
		},
		{
			name: "empty content",
			comment: Comment{
				ID:          uuid.New().String(),
				UserID:      uuid.New().String(),
				MediaItemID: uuid.New().String(),
				Content:     "",
				Status:      CommentStatusActive,
			},
			wantErr: true,
		},
		{
			name: "content too long",
			comment: Comment{
				ID:          uuid.New().String(),
				UserID:      uuid.New().String(),
				MediaItemID: uuid.New().String(),
				Content:     string(make([]byte, 1001)), // 1001 characters
				Status:      CommentStatusActive,
			},
			wantErr: true,
		},
		{
			name: "missing user ID",
			comment: Comment{
				ID:          uuid.New().String(),
				UserID:      "",
				MediaItemID: uuid.New().String(),
				Content:     "Valid content",
				Status:      CommentStatusActive,
			},
			wantErr: true,
		},
		{
			name: "missing media item ID",
			comment: Comment{
				ID:          uuid.New().String(),
				UserID:      uuid.New().String(),
				MediaItemID: "",
				Content:     "Valid content",
				Status:      CommentStatusActive,
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.comment.Validate()
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestComment_IsReply(t *testing.T) {
	parentID := uuid.New().String()
	
	tests := []struct {
		name     string
		comment  Comment
		expected bool
	}{
		{
			name: "is reply",
			comment: Comment{
				ParentID: &parentID,
			},
			expected: true,
		},
		{
			name: "is not reply",
			comment: Comment{
				ParentID: nil,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.comment.IsReply())
		})
	}
}

func TestComment_IsActive(t *testing.T) {
	tests := []struct {
		name     string
		comment  Comment
		expected bool
	}{
		{
			name: "active comment",
			comment: Comment{
				Status: CommentStatusActive,
			},
			expected: true,
		},
		{
			name: "deleted comment",
			comment: Comment{
				Status: CommentStatusDeleted,
			},
			expected: false,
		},
		{
			name: "moderated comment",
			comment: Comment{
				Status: CommentStatusModerated,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.comment.IsActive())
		})
	}
}

func TestComment_IsDeleted(t *testing.T) {
	now := time.Now()
	
	tests := []struct {
		name     string
		comment  Comment
		expected bool
	}{
		{
			name: "deleted by status",
			comment: Comment{
				Status: CommentStatusDeleted,
			},
			expected: true,
		},
		{
			name: "deleted by timestamp",
			comment: Comment{
				Status:    CommentStatusActive,
				DeletedAt: &now,
			},
			expected: true,
		},
		{
			name: "not deleted",
			comment: Comment{
				Status:    CommentStatusActive,
				DeletedAt: nil,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.comment.IsDeleted())
		})
	}
}

func TestComment_CanBeEdited(t *testing.T) {
	now := time.Now()
	
	tests := []struct {
		name     string
		comment  Comment
		expected bool
	}{
		{
			name: "can be edited",
			comment: Comment{
				Status:    CommentStatusActive,
				DeletedAt: nil,
			},
			expected: true,
		},
		{
			name: "cannot be edited - deleted",
			comment: Comment{
				Status:    CommentStatusDeleted,
				DeletedAt: nil,
			},
			expected: false,
		},
		{
			name: "cannot be edited - soft deleted",
			comment: Comment{
				Status:    CommentStatusActive,
				DeletedAt: &now,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.comment.CanBeEdited())
		})
	}
}

func TestComment_SoftDelete(t *testing.T) {
	comment := Comment{
		Status: CommentStatusActive,
	}
	
	comment.SoftDelete()
	
	assert.Equal(t, CommentStatusDeleted, comment.Status)
	assert.NotNil(t, comment.DeletedAt)
	assert.True(t, comment.UpdatedAt.After(comment.CreatedAt))
}

func TestComment_SetEdited(t *testing.T) {
	comment := Comment{
		IsEdited: false,
	}
	
	comment.SetEdited()
	
	assert.True(t, comment.IsEdited)
	assert.True(t, comment.UpdatedAt.After(comment.CreatedAt))
}

func TestComment_GenerateID(t *testing.T) {
	comment := Comment{}
	comment.GenerateID()
	
	assert.NotEmpty(t, comment.ID)
	_, err := uuid.Parse(comment.ID)
	assert.NoError(t, err)
}

func TestComment_SetTimestamps(t *testing.T) {
	comment := Comment{}
	comment.SetTimestamps()
	
	assert.False(t, comment.CreatedAt.IsZero())
	assert.False(t, comment.UpdatedAt.IsZero())
	assert.Equal(t, comment.CreatedAt, comment.UpdatedAt)
}

func TestCommentQuery_SetDefaults(t *testing.T) {
	tests := []struct {
		name     string
		query    CommentQuery
		expected CommentQuery
	}{
		{
			name: "set all defaults",
			query: CommentQuery{},
			expected: CommentQuery{
				Page:      1,
				Limit:     20,
				SortBy:    "created_at",
				SortOrder: "desc",
			},
		},
		{
			name: "preserve existing values",
			query: CommentQuery{
				Page:      2,
				Limit:     10,
				SortBy:    "updated_at",
				SortOrder: "asc",
			},
			expected: CommentQuery{
				Page:      2,
				Limit:     10,
				SortBy:    "updated_at",
				SortOrder: "asc",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tt.query.SetDefaults()
			assert.Equal(t, tt.expected, tt.query)
		})
	}
}
