package models

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// MetricType represents the type of metric
type MetricType string

const (
	MetricTypeCounter   MetricType = "counter"
	MetricTypeGauge     MetricType = "gauge"
	MetricTypeHistogram MetricType = "histogram"
)

// MetricLabels represents labels for metric categorization
type MetricLabels map[string]string

// Value implements the driver.Valuer interface for database storage
func (m MetricLabels) Value() (driver.Value, error) {
	if m == nil {
		return nil, nil
	}
	return json.Marshal(m)
}

// Scan implements the sql.Scanner interface for database retrieval
func (m *MetricLabels) Scan(value interface{}) error {
	if value == nil {
		*m = nil
		return nil
	}

	bytes, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("cannot scan %T into MetricLabels", value)
	}

	return json.Unmarshal(bytes, m)
}

// SystemStats represents system statistics and metrics
type SystemStats struct {
	ID          uuid.UUID    `json:"id" db:"id"`
	MetricName  string       `json:"metric_name" db:"metric_name"`
	MetricValue float64      `json:"metric_value" db:"metric_value"`
	MetricType  MetricType   `json:"metric_type" db:"metric_type"`
	Labels      MetricLabels `json:"labels" db:"labels"`
	Timestamp   time.Time    `json:"timestamp" db:"timestamp"`
}

// NewSystemStats creates a new SystemStats instance
func NewSystemStats(metricName string, metricValue float64, metricType MetricType, labels MetricLabels) *SystemStats {
	return &SystemStats{
		ID:          uuid.New(),
		MetricName:  metricName,
		MetricValue: metricValue,
		MetricType:  metricType,
		Labels:      labels,
		Timestamp:   time.Now(),
	}
}

// Validate validates the SystemStats fields
func (s *SystemStats) Validate() error {
	if s.MetricName == "" {
		return fmt.Errorf("metric_name is required")
	}
	if !IsValidMetricType(s.MetricType) {
		return fmt.Errorf("invalid metric type: %s", s.MetricType)
	}
	return nil
}

// IsValidMetricType checks if the metric type is valid
func IsValidMetricType(metricType MetricType) bool {
	validTypes := []MetricType{
		MetricTypeCounter,
		MetricTypeGauge,
		MetricTypeHistogram,
	}

	for _, validType := range validTypes {
		if metricType == validType {
			return true
		}
	}
	return false
}

// Common metric names
const (
	MetricNameTotalUsers          = "total_users"
	MetricNameActiveUsers         = "active_users"
	MetricNameTotalContent        = "total_content"
	MetricNamePendingContent      = "pending_content"
	MetricNameApprovedContent     = "approved_content"
	MetricNameRejectedContent     = "rejected_content"
	MetricNameTotalComments       = "total_comments"
	MetricNameTotalPayments       = "total_payments"
	MetricNameTotalRevenue        = "total_revenue"
	MetricNameSystemUptime        = "system_uptime"
	MetricNameErrorRate           = "error_rate"
	MetricNameResponseTime        = "response_time"
	MetricNameDatabaseConnections = "database_connections"
	MetricNameMemoryUsage         = "memory_usage"
	MetricNameCPUUsage            = "cpu_usage"
	MetricNameDiskUsage           = "disk_usage"
)

// Common label keys
const (
	LabelKeyService       = "service"
	LabelKeyStatus        = "status"
	LabelKeyType          = "type"
	LabelKeyUserRole      = "user_role"
	LabelKeyContentType   = "content_type"
	LabelKeyPaymentStatus = "payment_status"
	LabelKeyErrorCode     = "error_code"
	LabelKeyEndpoint      = "endpoint"
	LabelKeyMethod        = "method"
)
