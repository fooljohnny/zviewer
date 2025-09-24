package services

import (
	"zviewer-admin-service/internal/models"
	"zviewer-admin-service/internal/repositories"

	"github.com/google/uuid"
)

// SystemService handles system management business logic
type SystemService struct {
	systemStatsRepo *repositories.SystemStatsRepository
	adminActionRepo *repositories.AdminActionRepository
}

// NewSystemService creates a new system service
func NewSystemService(systemStatsRepo *repositories.SystemStatsRepository, adminActionRepo *repositories.AdminActionRepository) *SystemService {
	return &SystemService{
		systemStatsRepo: systemStatsRepo,
		adminActionRepo: adminActionRepo,
	}
}

// GetOverviewStats retrieves system overview statistics
func (s *SystemService) GetOverviewStats() (map[string]interface{}, error) {
	stats := make(map[string]interface{})

	// Get various metrics
	metrics := []string{
		models.MetricNameTotalUsers,
		models.MetricNameActiveUsers,
		models.MetricNameTotalContent,
		models.MetricNamePendingContent,
		models.MetricNameApprovedContent,
		models.MetricNameRejectedContent,
		models.MetricNameTotalComments,
		models.MetricNameTotalPayments,
		models.MetricNameTotalRevenue,
		models.MetricNameSystemUptime,
		models.MetricNameErrorRate,
		models.MetricNameResponseTime,
	}

	for _, metricName := range metrics {
		stat, err := s.systemStatsRepo.GetLatestByMetricName(metricName)
		if err != nil {
			// If metric doesn't exist, use default value
			stats[metricName] = 0
		} else {
			stats[metricName] = stat.MetricValue
		}
	}

	return stats, nil
}

// GetUserStats retrieves user statistics
func (s *SystemService) GetUserStats() (map[string]interface{}, error) {
	stats := make(map[string]interface{})

	userMetrics := []string{
		models.MetricNameTotalUsers,
		models.MetricNameActiveUsers,
	}

	for _, metricName := range userMetrics {
		stat, err := s.systemStatsRepo.GetLatestByMetricName(metricName)
		if err != nil {
			stats[metricName] = 0
		} else {
			stats[metricName] = stat.MetricValue
		}
	}

	return stats, nil
}

// GetContentStats retrieves content statistics
func (s *SystemService) GetContentStats() (map[string]interface{}, error) {
	stats := make(map[string]interface{})

	contentMetrics := []string{
		models.MetricNameTotalContent,
		models.MetricNamePendingContent,
		models.MetricNameApprovedContent,
		models.MetricNameRejectedContent,
	}

	for _, metricName := range contentMetrics {
		stat, err := s.systemStatsRepo.GetLatestByMetricName(metricName)
		if err != nil {
			stats[metricName] = 0
		} else {
			stats[metricName] = stat.MetricValue
		}
	}

	return stats, nil
}

// GetPaymentStats retrieves payment statistics
func (s *SystemService) GetPaymentStats() (map[string]interface{}, error) {
	stats := make(map[string]interface{})

	paymentMetrics := []string{
		models.MetricNameTotalPayments,
		models.MetricNameTotalRevenue,
	}

	for _, metricName := range paymentMetrics {
		stat, err := s.systemStatsRepo.GetLatestByMetricName(metricName)
		if err != nil {
			stats[metricName] = 0
		} else {
			stats[metricName] = stat.MetricValue
		}
	}

	return stats, nil
}

// GetAuditLogs retrieves audit logs
func (s *SystemService) GetAuditLogs(page, limit int, filters map[string]interface{}) ([]*models.AdminAction, int, error) {
	offset := (page - 1) * limit
	return s.adminActionRepo.List(offset, limit, filters)
}

// UpdateMetric updates a system metric
func (s *SystemService) UpdateMetric(metricName string, value float64, labels models.MetricLabels) error {
	stats := models.NewSystemStats(metricName, value, models.MetricTypeGauge, labels)
	return s.systemStatsRepo.Create(stats)
}

// RecordAdminAction records an admin action
func (s *SystemService) RecordAdminAction(adminUserID uuid.UUID, actionType models.AdminActionType, targetType models.TargetType, targetID *uuid.UUID, description string, metadata models.JSONMetadata) error {
	action := models.NewAdminAction(adminUserID, actionType, targetType, targetID, description, metadata)
	return s.adminActionRepo.Create(action)
}
