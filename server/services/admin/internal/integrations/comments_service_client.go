package integrations

import (
	"zviewer-admin-service/internal/config"
)

// CommentsServiceClient handles communication with the Comments Service
type CommentsServiceClient struct {
	baseURL string
}

// NewCommentsServiceClient creates a new Comments Service client
func NewCommentsServiceClient(servicesConfig config.ServicesConfig) *CommentsServiceClient {
	return &CommentsServiceClient{
		baseURL: servicesConfig.CommentsServiceURL,
	}
}

// TODO: Implement Comments Service integration methods
