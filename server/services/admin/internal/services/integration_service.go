package services

import (
	"zviewer-admin-service/internal/config"
	"zviewer-admin-service/internal/integrations"
)

// IntegrationService handles integration with other services
type IntegrationService struct {
	UserService     *integrations.UserServiceClient
	MediaService    *integrations.MediaServiceClient
	CommentsService *integrations.CommentsServiceClient
	PaymentService  *integrations.PaymentServiceClient
}

// NewIntegrationService creates a new integration service
func NewIntegrationService(servicesConfig config.ServicesConfig) *IntegrationService {
	return &IntegrationService{
		UserService:     integrations.NewUserServiceClient(servicesConfig),
		MediaService:    integrations.NewMediaServiceClient(servicesConfig),
		CommentsService: integrations.NewCommentsServiceClient(servicesConfig),
		PaymentService:  integrations.NewPaymentServiceClient(servicesConfig),
	}
}
