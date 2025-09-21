package services

import (
	"testing"

	"zviewer-comments-service/internal/config"
	"zviewer-comments-service/internal/models"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockCommentRepository is a mock implementation of CommentRepository
type MockCommentRepository struct {
	mock.Mock
}

func (m *MockCommentRepository) Create(comment *models.Comment) error {
	args := m.Called(comment)
	return args.Error(0)
}

func (m *MockCommentRepository) GetByID(id string) (*models.Comment, error) {
	args := m.Called(id)
	return args.Get(0).(*models.Comment), args.Error(1)
}

func (m *MockCommentRepository) Update(comment *models.Comment) error {
	args := m.Called(comment)
	return args.Error(0)
}

func (m *MockCommentRepository) Delete(id string) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockCommentRepository) List(query models.CommentQuery) ([]models.Comment, int64, error) {
	args := m.Called(query)
	return args.Get(0).([]models.Comment), args.Get(1).(int64), args.Error(2)
}

func (m *MockCommentRepository) GetByMediaID(mediaID string, query models.CommentQuery) ([]models.Comment, int64, error) {
	args := m.Called(mediaID, query)
	return args.Get(0).([]models.Comment), args.Get(1).(int64), args.Error(2)
}

func (m *MockCommentRepository) GetReplies(parentID string, query models.CommentQuery) ([]models.Comment, int64, error) {
	args := m.Called(parentID, query)
	return args.Get(0).([]models.Comment), args.Get(1).(int64), args.Error(2)
}

func (m *MockCommentRepository) GetStats() (*models.CommentStats, error) {
	args := m.Called()
	return args.Get(0).(*models.CommentStats), args.Error(1)
}

func (m *MockCommentRepository) GetUserStats(userID string) (*models.UserCommentStats, error) {
	args := m.Called(userID)
	return args.Get(0).(*models.UserCommentStats), args.Error(1)
}

func (m *MockCommentRepository) GetMediaStats(mediaID string) (*models.MediaCommentStats, error) {
	args := m.Called(mediaID)
	return args.Get(0).(*models.MediaCommentStats), args.Error(1)
}

func (m *MockCommentRepository) ValidateMediaExists(mediaID string) error {
	args := m.Called(mediaID)
	return args.Error(0)
}

func (m *MockCommentRepository) ValidateUserExists(userID string) error {
	args := m.Called(userID)
	return args.Error(0)
}

func (m *MockCommentRepository) ValidateParentComment(parentID string) error {
	args := m.Called(parentID)
	return args.Error(0)
}

func TestCommentService_CreateComment(t *testing.T) {
	mockRepo := new(MockCommentRepository)
	config := &config.Config{
		MaxCommentLength:     1000,
		EnableProfanityFilter: false,
	}
	service := NewCommentService(mockRepo, config)

	t.Run("successful creation", func(t *testing.T) {
		req := models.CommentCreateRequest{
			MediaItemID: "media-123",
			Content:     "This is a test comment",
		}
		userID := "user-123"

		mockRepo.On("ValidateMediaExists", "media-123").Return(nil)
		mockRepo.On("ValidateUserExists", "user-123").Return(nil)
		mockRepo.On("Create", mock.AnythingOfType("*models.Comment")).Return(nil)

		comment, err := service.CreateComment(req, userID)

		assert.NoError(t, err)
		assert.NotNil(t, comment)
		assert.Equal(t, "media-123", comment.MediaItemID)
		assert.Equal(t, "user-123", comment.UserID)
		assert.Equal(t, "This is a test comment", comment.Content)
		assert.Equal(t, models.CommentStatusActive, comment.Status)

		mockRepo.AssertExpectations(t)
	})

	t.Run("empty content", func(t *testing.T) {
		req := models.CommentCreateRequest{
			MediaItemID: "media-123",
			Content:     "",
		}
		userID := "user-123"

		comment, err := service.CreateComment(req, userID)

		assert.Error(t, err)
		assert.Nil(t, comment)
		assert.Contains(t, err.Error(), "comment content cannot be empty")
	})

	t.Run("content too long", func(t *testing.T) {
		req := models.CommentCreateRequest{
			MediaItemID: "media-123",
			Content:     string(make([]byte, 1001)),
		}
		userID := "user-123"

		comment, err := service.CreateComment(req, userID)

		assert.Error(t, err)
		assert.Nil(t, comment)
		assert.Contains(t, err.Error(), "comment content cannot exceed")
	})

	t.Run("media validation fails", func(t *testing.T) {
		req := models.CommentCreateRequest{
			MediaItemID: "invalid-media",
			Content:     "Valid content",
		}
		userID := "user-123"

		mockRepo.On("ValidateMediaExists", "invalid-media").Return(assert.AnError)

		comment, err := service.CreateComment(req, userID)

		assert.Error(t, err)
		assert.Nil(t, comment)
		assert.Contains(t, err.Error(), "media validation failed")

		mockRepo.AssertExpectations(t)
	})
}

func TestCommentService_UpdateComment(t *testing.T) {
	mockRepo := new(MockCommentRepository)
	config := &config.Config{
		MaxCommentLength:     1000,
		EnableProfanityFilter: false,
	}
	service := NewCommentService(mockRepo, config)

	t.Run("successful update", func(t *testing.T) {
		commentID := "comment-123"
		userID := "user-123"
		req := models.CommentUpdateRequest{
			Content: "Updated content",
		}

		existingComment := &models.Comment{
			ID:     commentID,
			UserID: userID,
			Status: models.CommentStatusActive,
		}

		mockRepo.On("GetByID", commentID).Return(existingComment, nil)
		mockRepo.On("Update", mock.AnythingOfType("*models.Comment")).Return(nil)

		comment, err := service.UpdateComment(commentID, req, userID)

		assert.NoError(t, err)
		assert.NotNil(t, comment)
		assert.Equal(t, "Updated content", comment.Content)
		assert.True(t, comment.IsEdited)

		mockRepo.AssertExpectations(t)
	})

	t.Run("unauthorized update", func(t *testing.T) {
		commentID := "comment-123"
		userID := "user-456" // Different user
		req := models.CommentUpdateRequest{
			Content: "Updated content",
		}

		existingComment := &models.Comment{
			ID:     commentID,
			UserID: "user-123", // Original owner
			Status: models.CommentStatusActive,
		}

		mockRepo.On("GetByID", commentID).Return(existingComment, nil)

		comment, err := service.UpdateComment(commentID, req, userID)

		assert.Error(t, err)
		assert.Nil(t, comment)
		assert.Contains(t, err.Error(), "not authorized")

		mockRepo.AssertExpectations(t)
	})
}

func TestCommentService_DeleteComment(t *testing.T) {
	mockRepo := new(MockCommentRepository)
	config := &config.Config{}
	service := NewCommentService(mockRepo, config)

	t.Run("successful deletion by owner", func(t *testing.T) {
		commentID := "comment-123"
		userID := "user-123"

		existingComment := &models.Comment{
			ID:     commentID,
			UserID: userID,
			Status: models.CommentStatusActive,
		}

		mockRepo.On("GetByID", commentID).Return(existingComment, nil)
		mockRepo.On("Delete", commentID).Return(nil)

		err := service.DeleteComment(commentID, userID, false)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})

	t.Run("successful deletion by admin", func(t *testing.T) {
		commentID := "comment-123"
		userID := "user-456" // Different user
		isAdmin := true

		existingComment := &models.Comment{
			ID:     commentID,
			UserID: "user-123", // Original owner
			Status: models.CommentStatusActive,
		}

		mockRepo.On("GetByID", commentID).Return(existingComment, nil)
		mockRepo.On("Delete", commentID).Return(nil)

		err := service.DeleteComment(commentID, userID, isAdmin)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})

	t.Run("unauthorized deletion", func(t *testing.T) {
		commentID := "comment-123"
		userID := "user-456" // Different user
		isAdmin := false

		existingComment := &models.Comment{
			ID:     commentID,
			UserID: "user-123", // Original owner
			Status: models.CommentStatusActive,
		}

		mockRepo.On("GetByID", commentID).Return(existingComment, nil)

		err := service.DeleteComment(commentID, userID, isAdmin)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "not authorized")
		mockRepo.AssertExpectations(t)
	})
}

func TestCommentService_validateCommentContent(t *testing.T) {
	config := &config.Config{
		MaxCommentLength: 1000,
	}
	service := NewCommentService(nil, config)

	tests := []struct {
		name    string
		content string
		wantErr bool
	}{
		{
			name:    "valid content",
			content: "This is valid content",
			wantErr: false,
		},
		{
			name:    "empty content",
			content: "",
			wantErr: true,
		},
		{
			name:    "whitespace only",
			content: "   ",
			wantErr: true,
		},
		{
			name:    "too short",
			content: "Hi",
			wantErr: true,
		},
		{
			name:    "too long",
			content: string(make([]byte, 1001)),
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := service.validateCommentContent(tt.content)
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestCommentService_sanitizeContent(t *testing.T) {
	config := &config.Config{}
	service := NewCommentService(nil, config)

	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "normal content",
			input:    "This is normal content",
			expected: "This is normal content",
		},
		{
			name:     "content with extra spaces",
			input:    "  This   has    extra    spaces  ",
			expected: "This has extra spaces",
		},
		{
			name:     "content with newlines",
			input:    "This\nhas\nnewlines",
			expected: "This has newlines",
		},
		{
			name:     "content with tabs",
			input:    "This\thas\ttabs",
			expected: "This has tabs",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := service.sanitizeContent(tt.input)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestCommentService_containsProfanity(t *testing.T) {
	config := &config.Config{}
	service := NewCommentService(nil, config)

	tests := []struct {
		name     string
		content  string
		expected bool
	}{
		{
			name:     "clean content",
			content:  "This is clean content",
			expected: false,
		},
		{
			name:     "content with spam",
			content:  "This is spam content",
			expected: true,
		},
		{
			name:     "content with scam",
			content:  "This is a scam",
			expected: true,
		},
		{
			name:     "content with fake",
			content:  "This is fake news",
			expected: true,
		},
		{
			name:     "content with bot",
			content:  "This is a bot",
			expected: true,
		},
		{
			name:     "case insensitive",
			content:  "This is SPAM content",
			expected: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := service.containsProfanity(tt.content)
			assert.Equal(t, tt.expected, result)
		})
	}
}
