package services

import (
	"bytes"
	"context"
	"io"
	"mime/multipart"
	"testing"

	"zviewer-media-service/internal/config"
	"zviewer-media-service/internal/models"
	"zviewer-media-service/internal/repositories"
	"zviewer-media-service/internal/storage"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockMediaRepository is a mock implementation of MediaRepository
type MockMediaRepository struct {
	mock.Mock
}

func (m *MockMediaRepository) Create(media *models.MediaItem) error {
	args := m.Called(media)
	return args.Error(0)
}

func (m *MockMediaRepository) GetByID(id string) (*models.MediaItem, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.MediaItem), args.Error(1)
}

func (m *MockMediaRepository) Update(media *models.MediaItem) error {
	args := m.Called(media)
	return args.Error(0)
}

func (m *MockMediaRepository) Delete(id string) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockMediaRepository) List(query models.MediaQuery) ([]models.MediaItem, int64, error) {
	args := m.Called(query)
	return args.Get(0).([]models.MediaItem), args.Get(1).(int64), args.Error(2)
}

func (m *MockMediaRepository) UpdateStatus(id string, status models.MediaStatus, approvedBy *string, rejectionReason *string) error {
	args := m.Called(id, status, approvedBy, rejectionReason)
	return args.Error(0)
}

// MockStorage is a mock implementation of Storage
type MockStorage struct {
	mock.Mock
}

func (m *MockStorage) SaveFile(ctx context.Context, filePath string, reader io.Reader) error {
	args := m.Called(ctx, filePath, reader)
	return args.Error(0)
}

func (m *MockStorage) GetFile(ctx context.Context, filePath string) (io.ReadCloser, error) {
	args := m.Called(ctx, filePath)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(io.ReadCloser), args.Error(1)
}

func (m *MockStorage) DeleteFile(ctx context.Context, filePath string) error {
	args := m.Called(ctx, filePath)
	return args.Error(0)
}

func (m *MockStorage) FileExists(ctx context.Context, filePath string) (bool, error) {
	args := m.Called(ctx, filePath)
	return args.Bool(0), args.Error(1)
}

func (m *MockStorage) GetFileSize(ctx context.Context, filePath string) (int64, error) {
	args := m.Called(ctx, filePath)
	return args.Get(0).(int64), args.Error(1)
}

func (m *MockStorage) GetFileURL(ctx context.Context, filePath string) (string, error) {
	args := m.Called(ctx, filePath)
	return args.String(0), args.Error(1)
}

func TestMediaService_UploadMedia(t *testing.T) {
	// Setup
	mockRepo := &MockMediaRepository{}
	mockStorage := &MockStorage{}
	cfg := &config.Config{
		MaxImageSize: 100 * 1024 * 1024,
		MaxVideoSize: 500 * 1024 * 1024,
	}

	service := &MediaService{
		mediaRepo:     mockRepo,
		storage:       mockStorage,
		pathGenerator: storage.NewPathGenerator(),
		config:        cfg,
	}

	// Test data
	fileHeader := &multipart.FileHeader{
		Filename: "test.jpg",
		Size:     1024,
		Header:   map[string][]string{"Content-Type": {"image/jpeg"}},
	}
	req := models.MediaUploadRequest{
		Title:       "Test Image",
		Description: "Test Description",
		Categories:  []string{"test"},
	}

	// Mock expectations
	mockStorage.On("SaveFile", mock.Anything, mock.Anything, mock.Anything).Return(nil)
	mockRepo.On("Create", mock.AnythingOfType("*models.MediaItem")).Return(nil)

	// Execute
	media, err := service.UploadMedia(context.Background(), fileHeader, req, "user123", "testuser")

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, media)
	assert.Equal(t, "Test Image", media.Title)
	assert.Equal(t, "user123", media.UserID)
	assert.Equal(t, models.MediaTypeImage, media.Type)

	mockRepo.AssertExpectations(t)
	mockStorage.AssertExpectations(t)
}

func TestMediaService_GetMedia(t *testing.T) {
	// Setup
	mockRepo := &MockMediaRepository{}
	mockStorage := &MockStorage{}
	cfg := &config.Config{}

	service := &MediaService{
		mediaRepo: mockRepo,
		storage:   mockStorage,
		config:    cfg,
	}

	// Test data
	expectedMedia := &models.MediaItem{
		ID:       "test123",
		Title:    "Test Media",
		UserID:   "user123",
		Type:     models.MediaTypeImage,
		FilePath: "2024/01/01/user123/test123.jpg",
	}

	// Mock expectations
	mockRepo.On("GetByID", "test123").Return(expectedMedia, nil)

	// Execute
	media, err := service.GetMedia(context.Background(), "test123")

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, media)
	assert.Equal(t, "test123", media.ID)
	assert.Equal(t, "Test Media", media.Title)

	mockRepo.AssertExpectations(t)
}

func TestMediaService_UpdateMedia(t *testing.T) {
	// Setup
	mockRepo := &MockMediaRepository{}
	mockStorage := &MockStorage{}
	cfg := &config.Config{}

	service := &MediaService{
		mediaRepo: mockRepo,
		storage:   mockStorage,
		config:    cfg,
	}

	// Test data
	existingMedia := &models.MediaItem{
		ID:       "test123",
		Title:    "Old Title",
		UserID:   "user123",
		Type:     models.MediaTypeImage,
		FilePath: "2024/01/01/user123/test123.jpg",
	}

	req := models.MediaUpdateRequest{
		Title:       "New Title",
		Description: "New Description",
		Categories:  []string{"updated"},
	}

	// Mock expectations
	mockRepo.On("GetByID", "test123").Return(existingMedia, nil)
	mockRepo.On("Update", mock.AnythingOfType("*models.MediaItem")).Return(nil)

	// Execute
	media, err := service.UpdateMedia(context.Background(), "test123", req, "user123")

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, media)
	assert.Equal(t, "New Title", media.Title)
	assert.Equal(t, "New Description", media.Description)

	mockRepo.AssertExpectations(t)
}

func TestMediaService_DeleteMedia(t *testing.T) {
	// Setup
	mockRepo := &MockMediaRepository{}
	mockStorage := &MockStorage{}
	cfg := &config.Config{}

	service := &MediaService{
		mediaRepo: mockRepo,
		storage:   mockStorage,
		config:    cfg,
	}

	// Test data
	existingMedia := &models.MediaItem{
		ID:       "test123",
		Title:    "Test Media",
		UserID:   "user123",
		Type:     models.MediaTypeImage,
		FilePath: "2024/01/01/user123/test123.jpg",
	}

	// Mock expectations
	mockRepo.On("GetByID", "test123").Return(existingMedia, nil)
	mockStorage.On("DeleteFile", mock.Anything, "2024/01/01/user123/test123.jpg").Return(nil)
	mockRepo.On("Delete", "test123").Return(nil)

	// Execute
	err := service.DeleteMedia(context.Background(), "test123", "user123")

	// Assert
	assert.NoError(t, err)

	mockRepo.AssertExpectations(t)
	mockStorage.AssertExpectations(t)
}

func TestMediaService_ListMedia(t *testing.T) {
	// Setup
	mockRepo := &MockMediaRepository{}
	mockStorage := &MockStorage{}
	cfg := &config.Config{}

	service := &MediaService{
		mediaRepo: mockRepo,
		storage:   mockStorage,
		config:    cfg,
	}

	// Test data
	query := models.MediaQuery{
		Page:  1,
		Limit: 10,
	}
	expectedMedia := []models.MediaItem{
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
	}

	// Mock expectations
	mockRepo.On("List", query).Return(expectedMedia, int64(2), nil)

	// Execute
	response, err := service.ListMedia(context.Background(), query)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, response)
	assert.Len(t, response.Media, 2)
	assert.Equal(t, int64(2), response.Total)
	assert.Equal(t, 1, response.Page)
	assert.Equal(t, 10, response.Limit)

	mockRepo.AssertExpectations(t)
}

func TestMediaService_validateFile(t *testing.T) {
	// Setup
	cfg := &config.Config{
		MaxImageSize: 100 * 1024 * 1024,
		MaxVideoSize: 500 * 1024 * 1024,
	}

	service := &MediaService{
		config: cfg,
	}

	// Test valid image file
	validImageFile := &multipart.FileHeader{
		Filename: "test.jpg",
		Size:     1024,
		Header:   map[string][]string{"Content-Type": {"image/jpeg"}},
	}

	err := service.validateFile(validImageFile)
	assert.NoError(t, err)

	// Test invalid file type
	invalidFile := &multipart.FileHeader{
		Filename: "test.txt",
		Size:     1024,
		Header:   map[string][]string{"Content-Type": {"text/plain"}},
	}

	err = service.validateFile(invalidFile)
	assert.Error(t, err)

	// Test file too large
	largeFile := &multipart.FileHeader{
		Filename: "test.jpg",
		Size:     200 * 1024 * 1024, // 200MB
		Header:   map[string][]string{"Content-Type": {"image/jpeg"}},
	}

	err = service.validateFile(largeFile)
	assert.Error(t, err)
}

func TestMediaService_determineMediaType(t *testing.T) {
	service := &MediaService{}

	// Test image types
	assert.Equal(t, models.MediaTypeImage, service.determineMediaType("test.jpg", "image/jpeg"))
	assert.Equal(t, models.MediaTypeImage, service.determineMediaType("test.png", "image/png"))
	assert.Equal(t, models.MediaTypeImage, service.determineMediaType("test.webp", "image/webp"))

	// Test video types
	assert.Equal(t, models.MediaTypeVideo, service.determineMediaType("test.mp4", "video/mp4"))
	assert.Equal(t, models.MediaTypeVideo, service.determineMediaType("test.webm", "video/webm"))

	// Test fallback to MIME type
	assert.Equal(t, models.MediaTypeImage, service.determineMediaType("test.unknown", "image/jpeg"))
	assert.Equal(t, models.MediaTypeVideo, service.determineMediaType("test.unknown", "video/mp4"))
}
