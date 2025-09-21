package handlers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"zviewer-comments-service/internal/models"
	"zviewer-comments-service/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockCommentService is a mock implementation of CommentService
type MockCommentService struct {
	mock.Mock
}

func (m *MockCommentService) CreateComment(req models.CommentCreateRequest, userID string) (*models.Comment, error) {
	args := m.Called(req, userID)
	return args.Get(0).(*models.Comment), args.Error(1)
}

func (m *MockCommentService) GetComment(id string) (*models.Comment, error) {
	args := m.Called(id)
	return args.Get(0).(*models.Comment), args.Error(1)
}

func (m *MockCommentService) UpdateComment(id string, req models.CommentUpdateRequest, userID string) (*models.Comment, error) {
	args := m.Called(id, req, userID)
	return args.Get(0).(*models.Comment), args.Error(1)
}

func (m *MockCommentService) DeleteComment(id string, userID string, isAdmin bool) error {
	args := m.Called(id, userID, isAdmin)
	return args.Error(0)
}

func (m *MockCommentService) ListComments(query models.CommentQuery) (*models.CommentListResponse, error) {
	args := m.Called(query)
	return args.Get(0).(*models.CommentListResponse), args.Error(1)
}

func (m *MockCommentService) GetCommentsByMedia(mediaID string, query models.CommentQuery) (*models.CommentListResponse, error) {
	args := m.Called(mediaID, query)
	return args.Get(0).(*models.CommentListResponse), args.Error(1)
}

func (m *MockCommentService) ReplyToComment(parentID string, req models.CommentReplyRequest, userID string) (*models.Comment, error) {
	args := m.Called(parentID, req, userID)
	return args.Get(0).(*models.Comment), args.Error(1)
}

func (m *MockCommentService) GetReplies(parentID string, query models.CommentQuery) (*models.CommentListResponse, error) {
	args := m.Called(parentID, query)
	return args.Get(0).(*models.CommentListResponse), args.Error(1)
}

func (m *MockCommentService) GetStats() (*models.CommentStats, error) {
	args := m.Called()
	return args.Get(0).(*models.CommentStats), args.Error(1)
}

func (m *MockCommentService) GetUserStats(userID string) (*models.UserCommentStats, error) {
	args := m.Called(userID)
	return args.Get(0).(*models.UserCommentStats), args.Error(1)
}

func (m *MockCommentService) GetMediaStats(mediaID string) (*models.MediaCommentStats, error) {
	args := m.Called(mediaID)
	return args.Get(0).(*models.MediaCommentStats), args.Error(1)
}

func (m *MockCommentService) ModerateComment(commentID string, action string, reason string, moderatorID string) error {
	args := m.Called(commentID, action, reason, moderatorID)
	return args.Error(0)
}

func TestCommentHandler_CreateComment(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("successful creation", func(t *testing.T) {
		mockService := new(MockCommentService)
		handler := NewCommentHandler(mockService)

		req := models.CommentCreateRequest{
			MediaItemID: "media-123",
			Content:     "This is a test comment",
		}

		expectedComment := &models.Comment{
			ID:          "comment-123",
			UserID:      "user-123",
			MediaItemID: "media-123",
			Content:     "This is a test comment",
			Status:      models.CommentStatusActive,
		}

		mockService.On("CreateComment", req, "user-123").Return(expectedComment, nil)

		// Create request
		reqBody, _ := json.Marshal(req)
		httpReq := httptest.NewRequest("POST", "/comments", bytes.NewBuffer(reqBody))
		httpReq.Header.Set("Content-Type", "application/json")
		httpReq.Header.Set("Authorization", "Bearer test-token")

		// Create response recorder
		w := httptest.NewRecorder()

		// Create gin context
		c, _ := gin.CreateTestContext(w)
		c.Request = httpReq
		c.Set("user_id", "user-123")

		// Call handler
		handler.CreateComment(c)

		// Assertions
		assert.Equal(t, http.StatusCreated, w.Code)

		var response models.Comment
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.Equal(t, expectedComment.ID, response.ID)
		assert.Equal(t, expectedComment.Content, response.Content)

		mockService.AssertExpectations(t)
	})

	t.Run("missing user ID", func(t *testing.T) {
		mockService := new(MockCommentService)
		handler := NewCommentHandler(mockService)

		req := models.CommentCreateRequest{
			MediaItemID: "media-123",
			Content:     "This is a test comment",
		}

		// Create request
		reqBody, _ := json.Marshal(req)
		httpReq := httptest.NewRequest("POST", "/comments", bytes.NewBuffer(reqBody))
		httpReq.Header.Set("Content-Type", "application/json")

		// Create response recorder
		w := httptest.NewRecorder()

		// Create gin context
		c, _ := gin.CreateTestContext(w)
		c.Request = httpReq
		// Don't set user_id

		// Call handler
		handler.CreateComment(c)

		// Assertions
		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})

	t.Run("invalid request data", func(t *testing.T) {
		mockService := new(MockCommentService)
		handler := NewCommentHandler(mockService)

		// Create request with invalid JSON
		httpReq := httptest.NewRequest("POST", "/comments", bytes.NewBufferString("invalid json"))
		httpReq.Header.Set("Content-Type", "application/json")
		httpReq.Header.Set("Authorization", "Bearer test-token")

		// Create response recorder
		w := httptest.NewRecorder()

		// Create gin context
		c, _ := gin.CreateTestContext(w)
		c.Request = httpReq
		c.Set("user_id", "user-123")

		// Call handler
		handler.CreateComment(c)

		// Assertions
		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}

func TestCommentHandler_GetComment(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("successful retrieval", func(t *testing.T) {
		mockService := new(MockCommentService)
		handler := NewCommentHandler(mockService)

		expectedComment := &models.Comment{
			ID:          "comment-123",
			UserID:      "user-123",
			MediaItemID: "media-123",
			Content:     "This is a test comment",
			Status:      models.CommentStatusActive,
		}

		mockService.On("GetComment", "comment-123").Return(expectedComment, nil)

		// Create request
		httpReq := httptest.NewRequest("GET", "/comments/comment-123", nil)

		// Create response recorder
		w := httptest.NewRecorder()

		// Create gin context
		c, _ := gin.CreateTestContext(w)
		c.Request = httpReq
		c.Params = gin.Params{{Key: "id", Value: "comment-123"}}

		// Call handler
		handler.GetComment(c)

		// Assertions
		assert.Equal(t, http.StatusOK, w.Code)

		var response models.Comment
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.Equal(t, expectedComment.ID, response.ID)
		assert.Equal(t, expectedComment.Content, response.Content)

		mockService.AssertExpectations(t)
	})

	t.Run("comment not found", func(t *testing.T) {
		mockService := new(MockCommentService)
		handler := NewCommentHandler(mockService)

		mockService.On("GetComment", "comment-123").Return((*models.Comment)(nil), assert.AnError)

		// Create request
		httpReq := httptest.NewRequest("GET", "/comments/comment-123", nil)

		// Create response recorder
		w := httptest.NewRecorder()

		// Create gin context
		c, _ := gin.CreateTestContext(w)
		c.Request = httpReq
		c.Params = gin.Params{{Key: "id", Value: "comment-123"}}

		// Call handler
		handler.GetComment(c)

		// Assertions
		assert.Equal(t, http.StatusNotFound, w.Code)

		mockService.AssertExpectations(t)
	})
}

func TestCommentHandler_UpdateComment(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("successful update", func(t *testing.T) {
		mockService := new(MockCommentService)
		handler := NewCommentHandler(mockService)

		req := models.CommentUpdateRequest{
			Content: "Updated content",
		}

		expectedComment := &models.Comment{
			ID:          "comment-123",
			UserID:      "user-123",
			MediaItemID: "media-123",
			Content:     "Updated content",
			Status:      models.CommentStatusActive,
			IsEdited:    true,
		}

		mockService.On("UpdateComment", "comment-123", req, "user-123").Return(expectedComment, nil)

		// Create request
		reqBody, _ := json.Marshal(req)
		httpReq := httptest.NewRequest("PUT", "/comments/comment-123", bytes.NewBuffer(reqBody))
		httpReq.Header.Set("Content-Type", "application/json")
		httpReq.Header.Set("Authorization", "Bearer test-token")

		// Create response recorder
		w := httptest.NewRecorder()

		// Create gin context
		c, _ := gin.CreateTestContext(w)
		c.Request = httpReq
		c.Params = gin.Params{{Key: "id", Value: "comment-123"}}
		c.Set("user_id", "user-123")

		// Call handler
		handler.UpdateComment(c)

		// Assertions
		assert.Equal(t, http.StatusOK, w.Code)

		var response models.Comment
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.Equal(t, expectedComment.ID, response.ID)
		assert.Equal(t, expectedComment.Content, response.Content)
		assert.True(t, response.IsEdited)

		mockService.AssertExpectations(t)
	})
}

func TestCommentHandler_DeleteComment(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("successful deletion by owner", func(t *testing.T) {
		mockService := new(MockCommentService)
		handler := NewCommentHandler(mockService)

		mockService.On("DeleteComment", "comment-123", "user-123", false).Return(nil)

		// Create request
		httpReq := httptest.NewRequest("DELETE", "/comments/comment-123", nil)
		httpReq.Header.Set("Authorization", "Bearer test-token")

		// Create response recorder
		w := httptest.NewRecorder()

		// Create gin context
		c, _ := gin.CreateTestContext(w)
		c.Request = httpReq
		c.Params = gin.Params{{Key: "id", Value: "comment-123"}}
		c.Set("user_id", "user-123")
		c.Set("user_role", "user")

		// Call handler
		handler.DeleteComment(c)

		// Assertions
		assert.Equal(t, http.StatusOK, w.Code)

		var response map[string]string
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.Equal(t, "Comment deleted successfully", response["message"])

		mockService.AssertExpectations(t)
	})

	t.Run("successful deletion by admin", func(t *testing.T) {
		mockService := new(MockCommentService)
		handler := NewCommentHandler(mockService)

		mockService.On("DeleteComment", "comment-123", "admin-123", true).Return(nil)

		// Create request
		httpReq := httptest.NewRequest("DELETE", "/comments/comment-123", nil)
		httpReq.Header.Set("Authorization", "Bearer test-token")

		// Create response recorder
		w := httptest.NewRecorder()

		// Create gin context
		c, _ := gin.CreateTestContext(w)
		c.Request = httpReq
		c.Params = gin.Params{{Key: "id", Value: "comment-123"}}
		c.Set("user_id", "admin-123")
		c.Set("user_role", "admin")

		// Call handler
		handler.DeleteComment(c)

		// Assertions
		assert.Equal(t, http.StatusOK, w.Code)

		mockService.AssertExpectations(t)
	})
}

func TestCommentHandler_ListComments(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("successful listing", func(t *testing.T) {
		mockService := new(MockCommentService)
		handler := NewCommentHandler(mockService)

		expectedResponse := &models.CommentListResponse{
			Comments: []models.Comment{
				{
					ID:          "comment-1",
					UserID:      "user-1",
					MediaItemID: "media-1",
					Content:     "Comment 1",
					Status:      models.CommentStatusActive,
				},
				{
					ID:          "comment-2",
					UserID:      "user-2",
					MediaItemID: "media-1",
					Content:     "Comment 2",
					Status:      models.CommentStatusActive,
				},
			},
			Total:   2,
			Page:    1,
			Limit:   20,
			HasMore: false,
		}

		mockService.On("ListComments", mock.AnythingOfType("models.CommentQuery")).Return(expectedResponse, nil)

		// Create request
		httpReq := httptest.NewRequest("GET", "/comments", nil)

		// Create response recorder
		w := httptest.NewRecorder()

		// Create gin context
		c, _ := gin.CreateTestContext(w)
		c.Request = httpReq

		// Call handler
		handler.ListComments(c)

		// Assertions
		assert.Equal(t, http.StatusOK, w.Code)

		var response models.CommentListResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.Equal(t, expectedResponse.Total, response.Total)
		assert.Equal(t, len(expectedResponse.Comments), len(response.Comments))

		mockService.AssertExpectations(t)
	})
}
