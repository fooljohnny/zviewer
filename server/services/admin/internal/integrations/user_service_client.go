package integrations

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"zviewer-admin-service/internal/config"
	"zviewer-admin-service/internal/models"

	"github.com/google/uuid"
)

// UserServiceClient handles communication with the User Service
type UserServiceClient struct {
	baseURL    string
	httpClient *http.Client
}

// User represents a user from the User Service
type User struct {
	ID          uuid.UUID `json:"id"`
	Email       string    `json:"email"`
	Username    string    `json:"username"`
	DisplayName string    `json:"display_name"`
	Role        string    `json:"role"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// CreateUserRequest represents a request to create a user
type CreateUserRequest struct {
	Email       string `json:"email"`
	Username    string `json:"username"`
	DisplayName string `json:"display_name"`
	Password    string `json:"password"`
	Role        string `json:"role"`
}

// UpdateUserRequest represents a request to update a user
type UpdateUserRequest struct {
	Email       *string `json:"email,omitempty"`
	Username    *string `json:"username,omitempty"`
	DisplayName *string `json:"display_name,omitempty"`
	Role        *string `json:"role,omitempty"`
	Status      *string `json:"status,omitempty"`
}

// UserListResponse represents the response from listing users
type UserListResponse struct {
	Users      []User `json:"users"`
	Total      int    `json:"total"`
	Page       int    `json:"page"`
	Limit      int    `json:"limit"`
	TotalPages int    `json:"total_pages"`
}

// NewUserServiceClient creates a new User Service client
func NewUserServiceClient(servicesConfig config.ServicesConfig) *UserServiceClient {
	return &UserServiceClient{
		baseURL: servicesConfig.UserServiceURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// GetUser retrieves a user by ID
func (c *UserServiceClient) GetUser(userID uuid.UUID) (*User, error) {
	url := fmt.Sprintf("%s/api/v1/users/%s", c.baseURL, userID.String())

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return nil, fmt.Errorf("user not found")
	}

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("user service error: %s", string(body))
	}

	var user User
	if err := json.NewDecoder(resp.Body).Decode(&user); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &user, nil
}

// ListUsers retrieves a list of users with pagination
func (c *UserServiceClient) ListUsers(page, limit int, filters map[string]string) (*UserListResponse, error) {
	url := fmt.Sprintf("%s/api/v1/users?page=%d&limit=%d", c.baseURL, page, limit)

	// Add filters to URL
	for key, value := range filters {
		url += fmt.Sprintf("&%s=%s", key, value)
	}

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("user service error: %s", string(body))
	}

	var userList UserListResponse
	if err := json.NewDecoder(resp.Body).Decode(&userList); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &userList, nil
}

// CreateUser creates a new user
func (c *UserServiceClient) CreateUser(req CreateUserRequest) (*User, error) {
	url := fmt.Sprintf("%s/api/v1/users", c.baseURL)

	jsonData, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusCreated {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("user service error: %s", string(body))
	}

	var user User
	if err := json.NewDecoder(resp.Body).Decode(&user); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &user, nil
}

// UpdateUser updates an existing user
func (c *UserServiceClient) UpdateUser(userID uuid.UUID, req UpdateUserRequest) (*User, error) {
	url := fmt.Sprintf("%s/api/v1/users/%s", c.baseURL, userID.String())

	jsonData, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequest("PUT", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return nil, fmt.Errorf("user not found")
	}

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("user service error: %s", string(body))
	}

	var user User
	if err := json.NewDecoder(resp.Body).Decode(&user); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &user, nil
}

// DeleteUser deletes a user
func (c *UserServiceClient) DeleteUser(userID uuid.UUID) error {
	url := fmt.Sprintf("%s/api/v1/users/%s", c.baseURL, userID.String())

	req, err := http.NewRequest("DELETE", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return fmt.Errorf("user not found")
	}

	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("user service error: %s", string(body))
	}

	return nil
}

// UpdateUserRole updates a user's role
func (c *UserServiceClient) UpdateUserRole(userID uuid.UUID, role string) (*User, error) {
	req := UpdateUserRequest{Role: &role}
	return c.UpdateUser(userID, req)
}

// UpdateUserStatus updates a user's status
func (c *UserServiceClient) UpdateUserStatus(userID uuid.UUID, status string) (*User, error) {
	req := UpdateUserRequest{Status: &status}
	return c.UpdateUser(userID, req)
}

// GetUserActivity retrieves user activity logs
func (c *UserServiceClient) GetUserActivity(userID uuid.UUID, page, limit int) ([]models.AdminAction, error) {
	url := fmt.Sprintf("%s/api/v1/users/%s/activity?page=%d&limit=%d", c.baseURL, userID.String(), page, limit)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return nil, fmt.Errorf("user not found")
	}

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("user service error: %s", string(body))
	}

	var activities []models.AdminAction
	if err := json.NewDecoder(resp.Body).Decode(&activities); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return activities, nil
}

// HealthCheck checks if the User Service is healthy
func (c *UserServiceClient) HealthCheck() error {
	url := fmt.Sprintf("%s/health", c.baseURL)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("user service is not healthy")
	}

	return nil
}
