package integrations

import (
	"zviewer-admin-service/internal/config"
)

// PaymentServiceClient handles communication with the Payment Service
type PaymentServiceClient struct {
	baseURL string
}

// NewPaymentServiceClient creates a new Payment Service client
func NewPaymentServiceClient(servicesConfig config.ServicesConfig) *PaymentServiceClient {
	return &PaymentServiceClient{
		baseURL: servicesConfig.PaymentServiceURL,
	}
}

// TODO: Implement Payment Service integration methods
