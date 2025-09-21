package handlers

import (
	"bytes"
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"zviewer-media-service/internal/models"
	"zviewer-media-service/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockMediaService is a mock implementation of MediaService
type MockMediaService struct {
	mock.Mock
}

func (m *MockMediaService) UploadMedia(ctx context.Context, file *multipart.FileHeader, req models.MediaUploadRequest, userID, userName string) (*models.MediaItem, error) {
	args := m.Called(ctx, file, req, userID, userName)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.MediaItem), args.Error(1)
}

func (m *MockMediaService) GetMedia(ctx context.Context, id string) (*models.MediaItem, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.MediaItem), args.Error(1)
}

func (m *MockMediaService) StreamMedia(ctx context.Context, id string) (io.ReadCloser, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(io.ReadCloser), args.Error(1)
}

func (m *MockMediaService) GetThumbnail(ctx context.Context, id string) (io.ReadCloser, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(io.ReadCloser), args.Error(1)
}

func (m *MockMediaService) UpdateMedia(ctx context.Context, id string, req models.MediaUpdateRequest, userID string) (*models.MediaItem, error) {
	args := m.Called(ctx, id, req, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.MediaItem), args.Error(1)
}

func (m *MockMediaService) DeleteMedia(ctx context.Context, id string, userID string) error {
	args := m.Called(ctx, id, userID)
	return args.Error(0)
}

func (m *MockMediaService) ListMedia(ctx context.Context, query models.MediaQuery) (*models.MediaListResponse, error) {
	args := m.Called(ctx, query)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.MediaListResponse), args.Error(1)
}

func TestMediaHandler_GetMedia(t *testing.T) {
	// Setup
	gin.SetMode(gin.TestMode)
	mockService := &MockMediaService{}
	handler := NewMediaHandler(mockService)

	// Test data
	expectedMedia := &models.MediaItem{
		ID:       "test123",
		Title:    "Test Media",
		UserID:   "user123",
		Type:     models.MediaTypeImage,
		FilePath: "2024/01/01/user123/test123.jpg",
	}

	// Mock expectations
	mockService.On("GetMedia", mock.Anything, "test123").Return(expectedMedia, nil)

	// Create request
	req, _ := http.NewRequest("GET", "/api/media/test123", nil)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = req

	// Execute
	handler.GetMedia(c)

	// Assert
	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), "test123")
	assert.Contains(t, w.Body.String(), "Test Media")

	mockService.AssertExpectations(t)
}

func TestMediaHandler_GetMedia_NotFound(t *testing.T) {
	// Setup
	gin.SetMode(gin.TestMode)
	mockService := &MockMediaService{}
	handler := NewMediaHandler(mockService)

	// Mock expectations
	mockService.On("GetMedia", mock.Anything, "nonexistent").Return(nil, assert.AnError)

	// Create request
	req, _ := http.NewRequest("GET", "/api/media/nonexistent", nil)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = req

	// Execute
	handler.GetMedia(c)

	// Assert
	assert.Equal(t, http.StatusNotFound, w.Code)
	assert.Contains(t, w.Body.String(), "Media not found")

	mockService.AssertExpectations(t)
}

func TestMediaHandler_UpdateMedia(t *testing.T) {
	// Setup
	gin.SetMode(gin.TestMode)
	mockService := &MockMediaService{}
	handler := NewMediaHandler(mockService)

	// Test data
	reqBody := `{"title": "Updated Title", "description": "Updated Description", "categories": ["updated"]}`
	expectedMedia := &models.MediaItem{
		ID:          "test123",
		Title:       "Updated Title",
		Description: "Updated Description",
		UserID:      "user123",
		Type:        models.MediaTypeImage,
		Categories:  []string{"updated"},
	}

	// Mock expectations
	mockService.On("UpdateMedia", mock.Anything, "test123", mock.AnythingOfType("models.MediaUpdateRequest"), "user123").Return(expectedMedia, nil)

	// Create request
	req, _ := http.NewRequest("PUT", "/api/media/test123", strings.NewReader(reqBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = req
	c.Set("user_id", "user123")

	// Execute
	handler.UpdateMedia(c)

	// Assert
	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), "Updated Title")

	mockService.AssertExpectations(t)
}

func TestMediaHandler_DeleteMedia(t *testing.T) {
	// Setup
	gin.SetMode(gin.TestMode)
	mockService := &MockMediaService{}
	handler := NewMediaHandler(mockService)

	// Mock expectations
	mockService.On("DeleteMedia", mock.Anything, "test123", "user123").Return(nil)

	// Create request
	req, _ := http.NewRequest("DELETE", "/api/media/test123", nil)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = req
	c.Set("user_id", "user123")

	// Execute
	handler.DeleteMedia(c)

	// Assert
	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), "deleted successfully")

	mockService.AssertExpectations(t)
}

func TestMediaHandler_ListMedia(t *testing.T) {
	// Setup
	gin.SetMode(gin.TestMode)
	mockService := &MockMediaService{}
	handler := NewMediaHandler(mockService)

	// Test data
	expectedResponse := &models.MediaListResponse{
		Media: []models.MediaItem{
			{
				ID:    "test1",
				Title: "Test Media 1",
				Type:  models.MediaTypeImage,
			},
			{
				ID:    "test2",
				Title: "Test Media 2",
				Type:  models.MediaTypeVideo,
			},
		},
		Total: 2,
		Page:  1,
		Limit: 10,
	}

	// Mock expectations
	mockService.On("ListMedia", mock.Anything, mock.AnythingOfType("models.MediaQuery")).Return(expectedResponse, nil)

	// Create request
	req, _ := http.NewRequest("GET", "/api/media?page=1&limit=10", nil)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = req

	// Execute
	handler.ListMedia(c)

	// Assert
	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), "test1")
	assert.Contains(t, w.Body.String(), "test2")

	mockService.AssertExpectations(t)
}

func TestMediaHandler_StreamMedia(t *testing.T) {
	// Setup
	gin.SetMode(gin.TestMode)
	mockService := &MockMediaService{}
	handler := NewMediaHandler(mockService)

	// Test data
	media := &models.MediaItem{
		ID:       "test123",
		Title:    "Test Media",
		MimeType: "image/jpeg",
		FileSize: 1024,
	}
	fileContent := "test file content"
	fileReader := io.NopCloser(strings.NewReader(fileContent))

	// Mock expectations
	mockService.On("GetMedia", mock.Anything, "test123").Return(media, nil)
	mockService.On("StreamMedia", mock.Anything, "test123").Return(fileReader, nil)

	// Create request
	req, _ := http.NewRequest("GET", "/api/media/test123/stream", nil)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = req

	// Execute
	handler.StreamMedia(c)

	// Assert
	assert.Equal(t, http.StatusOK, w.Code)
	assert.Equal(t, "image/jpeg", w.Header().Get("Content-Type"))
	assert.Equal(t, "1024", w.Header().Get("Content-Length"))
	assert.Contains(t, w.Body.String(), fileContent)

	mockService.AssertExpectations(t)
}

func TestMediaHandler_GetThumbnail(t *testing.T) {
	// Setup
	gin.SetMode(gin.TestMode)
	mockService := &MockMediaService{}
	handler := NewMediaHandler(mockService)

	// Test data
	thumbnailContent := "thumbnail content"
	thumbnailReader := io.NopCloser(strings.NewReader(thumbnailContent))

	// Mock expectations
	mockService.On("GetThumbnail", mock.Anything, "test123").Return(thumbnailReader, nil)

	// Create request
	req, _ := http.NewRequest("GET", "/api/media/test123/thumbnail", nil)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = req

	// Execute
	handler.GetThumbnail(c)

	// Assert
	assert.Equal(t, http.StatusOK, w.Code)
	assert.Equal(t, "image/jpeg", w.Header().Get("Content-Type"))
	assert.Contains(t, w.Body.String(), thumbnailContent)

	mockService.AssertExpectations(t)
}

func TestMediaHandler_GetThumbnail_NotFound(t *testing.T) {
	// Setup
	gin.SetMode(gin.TestMode)
	mockService := &MockMediaService{}
	handler := NewMediaHandler(mockService)

	// Mock expectations
	mockService.On("GetThumbnail", mock.Anything, "test123").Return(nil, assert.AnError)

	// Create request
	req, _ := http.NewRequest("GET", "/api/media/test123/thumbnail", nil)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = req

	// Execute
	handler.GetThumbnail(c)

	// Assert
	assert.Equal(t, http.StatusNotFound, w.Code)
	assert.Contains(t, w.Body.String(), "Thumbnail not available")

	mockService.AssertExpectations(t)
}
