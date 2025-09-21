package services

import (
	"testing"
	"time"

	"zviewer-server/internal/config"
	"zviewer-server/internal/models"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockUserRepository is a mock implementation of UserRepository
type MockUserRepository struct {
	mock.Mock
}

func (m *MockUserRepository) Create(user *models.User) error {
	args := m.Called(user)
	return args.Error(0)
}

func (m *MockUserRepository) GetByEmail(email string) (*models.User, error) {
	args := m.Called(email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockUserRepository) GetByID(id string) (*models.User, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockUserRepository) UpdateLastLogin(userID string) error {
	args := m.Called(userID)
	return args.Error(0)
}

func (m *MockUserRepository) Update(user *models.User) error {
	args := m.Called(user)
	return args.Error(0)
}

func (m *MockUserRepository) Delete(id string) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockUserRepository) EmailExists(email string) (bool, error) {
	args := m.Called(email)
	return args.Bool(0), args.Error(1)
}

func (m *MockUserRepository) List(limit, offset int) ([]*models.User, error) {
	args := m.Called(limit, offset)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*models.User), args.Error(1)
}

func TestAuthService_Register(t *testing.T) {
	mockRepo := new(MockUserRepository)
	jwtCfg := config.JWTConfig{
		SecretKey:  "test-secret",
		Expiration: 24 * time.Hour,
	}
	authService := NewAuthService(mockRepo, jwtCfg)

	t.Run("successful registration", func(t *testing.T) {
		req := &models.RegisterRequest{
			Email:           "test@example.com",
			Password:        "password123",
			ConfirmPassword: "password123",
		}

		mockRepo.On("EmailExists", req.Email).Return(false, nil)
		mockRepo.On("Create", mock.AnythingOfType("*models.User")).Return(nil)
		mockRepo.On("UpdateLastLogin", mock.AnythingOfType("string")).Return(nil)

		response, err := authService.Register(req)

		assert.NoError(t, err)
		assert.NotNil(t, response)
		assert.NotEmpty(t, response.Token)
		assert.Equal(t, req.Email, response.User.Email)
		assert.Equal(t, models.UserRoleUser, response.User.Role)
		assert.True(t, response.ExpiresAt.After(time.Now()))

		mockRepo.AssertExpectations(t)
	})

	t.Run("password mismatch", func(t *testing.T) {
		req := &models.RegisterRequest{
			Email:           "test@example.com",
			Password:        "password123",
			ConfirmPassword: "different123",
		}

		response, err := authService.Register(req)

		assert.Error(t, err)
		assert.Nil(t, response)
		assert.Contains(t, err.Error(), "passwords do not match")
	})

	t.Run("email already exists", func(t *testing.T) {
		req := &models.RegisterRequest{
			Email:           "existing@example.com",
			Password:        "password123",
			ConfirmPassword: "password123",
		}

		mockRepo.On("EmailExists", req.Email).Return(true, nil)

		response, err := authService.Register(req)

		assert.Error(t, err)
		assert.Nil(t, response)
		assert.Contains(t, err.Error(), "email already exists")

		mockRepo.AssertExpectations(t)
	})
}

func TestAuthService_Login(t *testing.T) {
	mockRepo := new(MockUserRepository)
	jwtCfg := config.JWTConfig{
		SecretKey:  "test-secret",
		Expiration: 24 * time.Hour,
	}
	authService := NewAuthService(mockRepo, jwtCfg)

	t.Run("successful login", func(t *testing.T) {
		req := &models.LoginRequest{
			Email:    "test@example.com",
			Password: "password123",
		}

		hashedPassword, _ := HashPassword("password123")
		user := &models.User{
			ID:           "user-id",
			Email:        "test@example.com",
			PasswordHash: hashedPassword,
			Role:         models.UserRoleUser,
		}

		mockRepo.On("GetByEmail", req.Email).Return(user, nil)
		mockRepo.On("UpdateLastLogin", user.ID).Return(nil)

		response, err := authService.Login(req)

		assert.NoError(t, err)
		assert.NotNil(t, response)
		assert.NotEmpty(t, response.Token)
		assert.Equal(t, req.Email, response.User.Email)
		assert.True(t, response.ExpiresAt.After(time.Now()))

		mockRepo.AssertExpectations(t)
	})

	t.Run("invalid credentials", func(t *testing.T) {
		req := &models.LoginRequest{
			Email:    "test@example.com",
			Password: "wrongpassword",
		}

		hashedPassword, _ := HashPassword("password123")
		user := &models.User{
			ID:           "user-id",
			Email:        "test@example.com",
			PasswordHash: hashedPassword,
			Role:         models.UserRoleUser,
		}

		mockRepo.On("GetByEmail", req.Email).Return(user, nil)

		response, err := authService.Login(req)

		assert.Error(t, err)
		assert.Nil(t, response)
		assert.Contains(t, err.Error(), "invalid credentials")

		mockRepo.AssertExpectations(t)
	})

	t.Run("user not found", func(t *testing.T) {
		req := &models.LoginRequest{
			Email:    "nonexistent@example.com",
			Password: "password123",
		}

		mockRepo.On("GetByEmail", req.Email).Return(nil, assert.AnError)

		response, err := authService.Login(req)

		assert.Error(t, err)
		assert.Nil(t, response)
		assert.Contains(t, err.Error(), "invalid credentials")

		mockRepo.AssertExpectations(t)
	})
}

func TestAuthService_ValidateToken(t *testing.T) {
	mockRepo := new(MockUserRepository)
	jwtCfg := config.JWTConfig{
		SecretKey:  "test-secret",
		Expiration: 24 * time.Hour,
	}
	authService := NewAuthService(mockRepo, jwtCfg)

	t.Run("valid token", func(t *testing.T) {
		user := &models.User{
			ID:    "user-id",
			Email: "test@example.com",
			Role:  models.UserRoleUser,
		}

		token, _, err := authService.generateToken(user)
		assert.NoError(t, err)

		userID, err := authService.ValidateToken(token)
		assert.NoError(t, err)
		assert.Equal(t, "user-id", userID)
	})

	t.Run("invalid token", func(t *testing.T) {
		userID, err := authService.ValidateToken("invalid-token")
		assert.Error(t, err)
		assert.Empty(t, userID)
	})
}

func TestHashPassword(t *testing.T) {
	password := "testpassword123"
	hashed, err := HashPassword(password)
	
	assert.NoError(t, err)
	assert.NotEmpty(t, hashed)
	assert.NotEqual(t, password, hashed)
}

func TestVerifyPassword(t *testing.T) {
	password := "testpassword123"
	hashed, _ := HashPassword(password)

	t.Run("correct password", func(t *testing.T) {
		err := VerifyPassword(hashed, password)
		assert.NoError(t, err)
	})

	t.Run("incorrect password", func(t *testing.T) {
		err := VerifyPassword(hashed, "wrongpassword")
		assert.Error(t, err)
	})
}
