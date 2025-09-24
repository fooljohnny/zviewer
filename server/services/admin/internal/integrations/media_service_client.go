package integrations

import (
	"zviewer-admin-service/internal/config"
)

// MediaServiceClient handles communication with the Media Service
type MediaServiceClient struct {
	baseURL string
}

// NewMediaServiceClient creates a new Media Service client
func NewMediaServiceClient(servicesConfig config.ServicesConfig) *MediaServiceClient {
	return &MediaServiceClient{
		baseURL: servicesConfig.MediaServiceURL,
	}
}

// TODO: Implement Media Service integration methods
