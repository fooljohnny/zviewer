package services

import (
	"fmt"

	"zviewer-admin-service/internal/integrations"
	"zviewer-admin-service/internal/models"
	"zviewer-admin-service/internal/repositories"

	"github.com/google/uuid"
)

// UserManagementService handles user management business logic
type UserManagementService struct {
	adminActionRepo    *repositories.AdminActionRepository
	integrationService *IntegrationService
}

// NewUserManagementService creates a new user management service
func NewUserManagementService(adminActionRepo *repositories.AdminActionRepository, integrationService *IntegrationService) *UserManagementService {
	return &UserManagementService{
		adminActionRepo:    adminActionRepo,
		integrationService: integrationService,
	}
}

// ListUsers retrieves a list of users
func (s *UserManagementService) ListUsers(page, limit int, filters map[string]string) ([]*integrations.User, int, error) {
	response, err := s.integrationService.UserService.ListUsers(page, limit, filters)
	if err != nil {
		return nil, 0, err
	}

	// Convert []User to []*User
	users := make([]*integrations.User, len(response.Users))
	for i := range response.Users {
		users[i] = &response.Users[i]
	}

	return users, response.Total, nil
}

// GetUser retrieves a user by ID
func (s *UserManagementService) GetUser(userID uuid.UUID) (*integrations.User, error) {
	return s.integrationService.UserService.GetUser(userID)
}

// CreateUser creates a new user
func (s *UserManagementService) CreateUser(email, username, displayName, password, role string) (*integrations.User, error) {
	req := integrations.CreateUserRequest{
		Email:       email,
		Username:    username,
		DisplayName: displayName,
		Password:    password,
		Role:        role,
	}

	user, err := s.integrationService.UserService.CreateUser(req)
	if err != nil {
		return nil, err
	}

	// Log admin action
	adminAction := models.NewAdminAction(
		uuid.New(), // TODO: Get actual admin user ID from context
		models.ActionTypeUserCreated,
		models.TargetTypeUser,
		&user.ID,
		fmt.Sprintf("Created user %s", user.Username),
		models.JSONMetadata{
			"user_id":  user.ID.String(),
			"username": user.Username,
			"email":    user.Email,
			"role":     user.Role,
		},
	)

	if err := s.adminActionRepo.Create(adminAction); err != nil {
		// Log error but don't fail the operation
		fmt.Printf("Failed to log admin action: %v\n", err)
	}

	return user, nil
}

// UpdateUser updates an existing user
func (s *UserManagementService) UpdateUser(userID uuid.UUID, email, username, displayName, role, status *string) (*integrations.User, error) {
	req := integrations.UpdateUserRequest{
		Email:       email,
		Username:    username,
		DisplayName: displayName,
		Role:        role,
		Status:      status,
	}

	user, err := s.integrationService.UserService.UpdateUser(userID, req)
	if err != nil {
		return nil, err
	}

	// Log admin action
	adminAction := models.NewAdminAction(
		uuid.New(), // TODO: Get actual admin user ID from context
		models.ActionTypeUserUpdated,
		models.TargetTypeUser,
		&user.ID,
		fmt.Sprintf("Updated user %s", user.Username),
		models.JSONMetadata{
			"user_id":  user.ID.String(),
			"username": user.Username,
			"email":    user.Email,
			"role":     user.Role,
			"status":   user.Status,
		},
	)

	if err := s.adminActionRepo.Create(adminAction); err != nil {
		// Log error but don't fail the operation
		fmt.Printf("Failed to log admin action: %v\n", err)
	}

	return user, nil
}

// DeleteUser deletes a user
func (s *UserManagementService) DeleteUser(userID uuid.UUID) error {
	// Get user info before deletion for logging
	user, err := s.integrationService.UserService.GetUser(userID)
	if err != nil {
		return err
	}

	err = s.integrationService.UserService.DeleteUser(userID)
	if err != nil {
		return err
	}

	// Log admin action
	adminAction := models.NewAdminAction(
		uuid.New(), // TODO: Get actual admin user ID from context
		models.ActionTypeUserDeleted,
		models.TargetTypeUser,
		&userID,
		fmt.Sprintf("Deleted user %s", user.Username),
		models.JSONMetadata{
			"user_id":  user.ID.String(),
			"username": user.Username,
			"email":    user.Email,
		},
	)

	if err := s.adminActionRepo.Create(adminAction); err != nil {
		// Log error but don't fail the operation
		fmt.Printf("Failed to log admin action: %v\n", err)
	}

	return nil
}

// UpdateUserRole updates a user's role
func (s *UserManagementService) UpdateUserRole(userID uuid.UUID, role string) (*integrations.User, error) {
	user, err := s.integrationService.UserService.UpdateUserRole(userID, role)
	if err != nil {
		return nil, err
	}

	// Log admin action
	adminAction := models.NewAdminAction(
		uuid.New(), // TODO: Get actual admin user ID from context
		models.ActionTypeUserRoleChanged,
		models.TargetTypeUser,
		&userID,
		fmt.Sprintf("Changed role for user %s to %s", user.Username, role),
		models.JSONMetadata{
			"user_id":  user.ID.String(),
			"username": user.Username,
			"old_role": user.Role, // This might not be accurate
			"new_role": role,
		},
	)

	if err := s.adminActionRepo.Create(adminAction); err != nil {
		// Log error but don't fail the operation
		fmt.Printf("Failed to log admin action: %v\n", err)
	}

	return user, nil
}

// UpdateUserStatus updates a user's status
func (s *UserManagementService) UpdateUserStatus(userID uuid.UUID, status string) (*integrations.User, error) {
	user, err := s.integrationService.UserService.UpdateUserStatus(userID, status)
	if err != nil {
		return nil, err
	}

	// Log admin action
	adminAction := models.NewAdminAction(
		uuid.New(), // TODO: Get actual admin user ID from context
		models.ActionTypeUserStatusChanged,
		models.TargetTypeUser,
		&userID,
		fmt.Sprintf("Changed status for user %s to %s", user.Username, status),
		models.JSONMetadata{
			"user_id":    user.ID.String(),
			"username":   user.Username,
			"old_status": user.Status, // This might not be accurate
			"new_status": status,
		},
	)

	if err := s.adminActionRepo.Create(adminAction); err != nil {
		// Log error but don't fail the operation
		fmt.Printf("Failed to log admin action: %v\n", err)
	}

	return user, nil
}

// GetUserActivity retrieves user activity logs
func (s *UserManagementService) GetUserActivity(userID uuid.UUID, page, limit int) ([]*models.AdminAction, error) {
	return s.adminActionRepo.GetByTargetID(string(models.TargetTypeUser), userID)
}
