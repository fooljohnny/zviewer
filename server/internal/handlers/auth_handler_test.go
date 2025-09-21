package handlers

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"zviewer-server/internal/config"
	"zviewer-server/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockAuthService is a mock implementation of AuthService
type MockAuthService struct {
	mock.Mock
}

func (m *MockAuthService) Register(req *models.RegisterRequest) (*models.AuthResponse, error) {
	args := m.Called(req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.AuthResponse), args.Error(1)
}

func (m *MockAuthService) Login(req *models.LoginRequest) (*models.AuthResponse, error) {
	args := m.Called(req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.AuthResponse), args.Error(1)
}

func (m *MockAuthService) GetUserByID(userID string) (*models.User, error) {
	args := m.Called(userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockAuthService) ValidateToken(tokenString string) (string, error) {
	args := m.Called(tokenString)
	return args.String(0), args.Error(1)
}

func setupTestRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	return gin.New()
}

func TestAuthHandler_Register(t *testing.T) {
	t.Run("successful registration", func(t *testing.T) {
		router := setupTestRouter()
		mockAuthService := new(MockAuthService)
		
		handler := &AuthHandler{
			authService: mockAuthService,
		}

		req := models.RegisterRequest{
			Email:           "test@example.com",
			Password:        "password123",
			ConfirmPassword: "password123",
		}

		expectedResponse := &models.AuthResponse{
			Token:     "test-token",
			User:      models.User{ID: "user-id", Email: "test@example.com"},
			ExpiresAt: time.Now().Add(24 * time.Hour),
		}

		mockAuthService.On("Register", &req).Return(expectedResponse, nil)

		router.POST("/register", handler.Register)

		jsonBody, _ := json.Marshal(req)
		reqBody := bytes.NewBuffer(jsonBody)
		request, _ := http.NewRequest("POST", "/register", reqBody)
		request.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, request)

		assert.Equal(t, http.StatusCreated, w.Code)
		
		var response models.AuthResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.Equal(t, expectedResponse.Token, response.Token)
		assert.Equal(t, expectedResponse.User.Email, response.User.Email)

		mockAuthService.AssertExpectations(t)
	})

	t.Run("invalid request data", func(t *testing.T) {
		router := setupTestRouter()
		handler := &AuthHandler{}

		router.POST("/register", handler.Register)

		invalidJSON := `{"email": "invalid-email"}`
		reqBody := bytes.NewBufferString(invalidJSON)
		request, _ := http.NewRequest("POST", "/register", reqBody)
		request.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, request)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		
		var response models.ErrorResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.Equal(t, "Invalid request data", response.Message)
	})

	t.Run("registration error", func(t *testing.T) {
		router := setupTestRouter()
		mockAuthService := new(MockAuthService)
		
		handler := &AuthHandler{
			authService: mockAuthService,
		}

		req := models.RegisterRequest{
			Email:           "test@example.com",
			Password:        "password123",
			ConfirmPassword: "password123",
		}

		mockAuthService.On("Register", &req).Return(nil, assert.AnError)

		router.POST("/register", handler.Register)

		jsonBody, _ := json.Marshal(req)
		reqBody := bytes.NewBuffer(jsonBody)
		request, _ := http.NewRequest("POST", "/register", reqBody)
		request.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, request)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		
		var response models.ErrorResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.NotEmpty(t, response.Message)

		mockAuthService.AssertExpectations(t)
	})
}

func TestAuthHandler_Login(t *testing.T) {
	t.Run("successful login", func(t *testing.T) {
		router := setupTestRouter()
		mockAuthService := new(MockAuthService)
		
		handler := &AuthHandler{
			authService: mockAuthService,
		}

		req := models.LoginRequest{
			Email:    "test@example.com",
			Password: "password123",
		}

		expectedResponse := &models.AuthResponse{
			Token:     "test-token",
			User:      models.User{ID: "user-id", Email: "test@example.com"},
			ExpiresAt: time.Now().Add(24 * time.Hour),
		}

		mockAuthService.On("Login", &req).Return(expectedResponse, nil)

		router.POST("/login", handler.Login)

		jsonBody, _ := json.Marshal(req)
		reqBody := bytes.NewBuffer(jsonBody)
		request, _ := http.NewRequest("POST", "/login", reqBody)
		request.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, request)

		assert.Equal(t, http.StatusOK, w.Code)
		
		var response models.AuthResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.Equal(t, expectedResponse.Token, response.Token)
		assert.Equal(t, expectedResponse.User.Email, response.User.Email)

		mockAuthService.AssertExpectations(t)
	})

	t.Run("invalid credentials", func(t *testing.T) {
		router := setupTestRouter()
		mockAuthService := new(MockAuthService)
		
		handler := &AuthHandler{
			authService: mockAuthService,
		}

		req := models.LoginRequest{
			Email:    "test@example.com",
			Password: "wrongpassword",
		}

		mockAuthService.On("Login", &req).Return(nil, assert.AnError)

		router.POST("/login", handler.Login)

		jsonBody, _ := json.Marshal(req)
		reqBody := bytes.NewBuffer(jsonBody)
		request, _ := http.NewRequest("POST", "/login", reqBody)
		request.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, request)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		
		var response models.ErrorResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.Equal(t, "Invalid credentials", response.Message)

		mockAuthService.AssertExpectations(t)
	})
}

func TestAuthHandler_Logout(t *testing.T) {
	router := setupTestRouter()
	handler := &AuthHandler{}

	// Mock the AuthRequired middleware to set user_id in context
	router.POST("/logout", func(c *gin.Context) {
		c.Set("user_id", "test-user-id")
		handler.Logout(c)
	})

	request, _ := http.NewRequest("POST", "/logout", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, request)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestAuthHandler_GetMe(t *testing.T) {
	t.Run("successful get me", func(t *testing.T) {
		router := setupTestRouter()
		mockAuthService := new(MockAuthService)
		
		handler := &AuthHandler{
			authService: mockAuthService,
		}

		expectedUser := &models.User{
			ID:    "user-id",
			Email: "test@example.com",
			Role:  models.UserRoleUser,
		}

		mockAuthService.On("GetUserByID", "test-user-id").Return(expectedUser, nil)

		// Mock the AuthRequired middleware to set user_id in context
		router.GET("/me", func(c *gin.Context) {
			c.Set("user_id", "test-user-id")
			handler.GetMe(c)
		})

		request, _ := http.NewRequest("GET", "/me", nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, request)

		assert.Equal(t, http.StatusOK, w.Code)
		
		var response models.User
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.Equal(t, expectedUser.Email, response.Email)

		mockAuthService.AssertExpectations(t)
	})

	t.Run("user not found", func(t *testing.T) {
		router := setupTestRouter()
		mockAuthService := new(MockAuthService)
		
		handler := &AuthHandler{
			authService: mockAuthService,
		}

		mockAuthService.On("GetUserByID", "test-user-id").Return(nil, assert.AnError)

		// Mock the AuthRequired middleware to set user_id in context
		router.GET("/me", func(c *gin.Context) {
			c.Set("user_id", "test-user-id")
			handler.GetMe(c)
		})

		request, _ := http.NewRequest("GET", "/me", nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, request)

		assert.Equal(t, http.StatusNotFound, w.Code)
		
		var response models.ErrorResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.Equal(t, "User not found", response.Message)

		mockAuthService.AssertExpectations(t)
	})
}
