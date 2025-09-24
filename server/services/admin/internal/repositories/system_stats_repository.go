package repositories

import (
	"database/sql"
	"fmt"
	"time"

	"zviewer-admin-service/internal/models"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

// SystemStatsRepository handles system statistics data operations
type SystemStatsRepository struct {
	db *sql.DB
}

// NewSystemStatsRepository creates a new system stats repository
func NewSystemStatsRepository(db *sql.DB) *SystemStatsRepository {
	return &SystemStatsRepository{db: db}
}

// Create creates a new system stats record
func (r *SystemStatsRepository) Create(stats *models.SystemStats) error {
	query := `
		INSERT INTO system_stats (id, metric_name, metric_value, metric_type, labels, timestamp)
		VALUES ($1, $2, $3, $4, $5, $6)
	`

	_, err := r.db.Exec(query,
		stats.ID,
		stats.MetricName,
		stats.MetricValue,
		stats.MetricType,
		stats.Labels,
		stats.Timestamp,
	)

	if err != nil {
		logrus.WithError(err).Error("Failed to create system stats")
		return fmt.Errorf("failed to create system stats: %w", err)
	}

	return nil
}

// GetByID retrieves system stats by ID
func (r *SystemStatsRepository) GetByID(id uuid.UUID) (*models.SystemStats, error) {
	query := `
		SELECT id, metric_name, metric_value, metric_type, labels, timestamp
		FROM system_stats
		WHERE id = $1
	`

	stats := &models.SystemStats{}
	err := r.db.QueryRow(query, id).Scan(
		&stats.ID,
		&stats.MetricName,
		&stats.MetricValue,
		&stats.MetricType,
		&stats.Labels,
		&stats.Timestamp,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("system stats not found")
		}
		logrus.WithError(err).Error("Failed to get system stats by ID")
		return nil, fmt.Errorf("failed to get system stats: %w", err)
	}

	return stats, nil
}

// List retrieves system stats with pagination and filtering
func (r *SystemStatsRepository) List(offset, limit int, filters map[string]interface{}) ([]*models.SystemStats, int, error) {
	// Build WHERE clause
	whereClause := "WHERE 1=1"
	args := []interface{}{}
	argIndex := 1

	if metricName, ok := filters["metric_name"].(string); ok {
		whereClause += fmt.Sprintf(" AND metric_name = $%d", argIndex)
		args = append(args, metricName)
		argIndex++
	}

	if metricType, ok := filters["metric_type"].(string); ok {
		whereClause += fmt.Sprintf(" AND metric_type = $%d", argIndex)
		args = append(args, metricType)
		argIndex++
	}

	if startDate, ok := filters["start_date"].(time.Time); ok {
		whereClause += fmt.Sprintf(" AND timestamp >= $%d", argIndex)
		args = append(args, startDate)
		argIndex++
	}

	if endDate, ok := filters["end_date"].(time.Time); ok {
		whereClause += fmt.Sprintf(" AND timestamp <= $%d", argIndex)
		args = append(args, endDate)
		argIndex++
	}

	// Count total records
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM system_stats %s", whereClause)
	var total int
	err := r.db.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		logrus.WithError(err).Error("Failed to count system stats")
		return nil, 0, fmt.Errorf("failed to count system stats: %w", err)
	}

	// Get paginated results
	query := fmt.Sprintf(`
		SELECT id, metric_name, metric_value, metric_type, labels, timestamp
		FROM system_stats
		%s
		ORDER BY timestamp DESC
		OFFSET $%d LIMIT $%d
	`, whereClause, argIndex, argIndex+1)

	args = append(args, offset, limit)

	rows, err := r.db.Query(query, args...)
	if err != nil {
		logrus.WithError(err).Error("Failed to list system stats")
		return nil, 0, fmt.Errorf("failed to list system stats: %w", err)
	}
	defer rows.Close()

	var statsList []*models.SystemStats
	for rows.Next() {
		stats := &models.SystemStats{}
		err := rows.Scan(
			&stats.ID,
			&stats.MetricName,
			&stats.MetricValue,
			&stats.MetricType,
			&stats.Labels,
			&stats.Timestamp,
		)
		if err != nil {
			logrus.WithError(err).Error("Failed to scan system stats")
			return nil, 0, fmt.Errorf("failed to scan system stats: %w", err)
		}
		statsList = append(statsList, stats)
	}

	return statsList, total, nil
}

// GetLatestByMetricName retrieves the latest stats for a specific metric
func (r *SystemStatsRepository) GetLatestByMetricName(metricName string) (*models.SystemStats, error) {
	query := `
		SELECT id, metric_name, metric_value, metric_type, labels, timestamp
		FROM system_stats
		WHERE metric_name = $1
		ORDER BY timestamp DESC
		LIMIT 1
	`

	stats := &models.SystemStats{}
	err := r.db.QueryRow(query, metricName).Scan(
		&stats.ID,
		&stats.MetricName,
		&stats.MetricValue,
		&stats.MetricType,
		&stats.Labels,
		&stats.Timestamp,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("system stats not found for metric: %s", metricName)
		}
		logrus.WithError(err).Error("Failed to get latest system stats by metric name")
		return nil, fmt.Errorf("failed to get latest system stats: %w", err)
	}

	return stats, nil
}

// GetByMetricNameAndTimeRange retrieves stats for a metric within a time range
func (r *SystemStatsRepository) GetByMetricNameAndTimeRange(metricName string, startTime, endTime time.Time) ([]*models.SystemStats, error) {
	query := `
		SELECT id, metric_name, metric_value, metric_type, labels, timestamp
		FROM system_stats
		WHERE metric_name = $1 AND timestamp >= $2 AND timestamp <= $3
		ORDER BY timestamp ASC
	`

	rows, err := r.db.Query(query, metricName, startTime, endTime)
	if err != nil {
		logrus.WithError(err).Error("Failed to get system stats by metric name and time range")
		return nil, fmt.Errorf("failed to get system stats by metric name and time range: %w", err)
	}
	defer rows.Close()

	var statsList []*models.SystemStats
	for rows.Next() {
		stats := &models.SystemStats{}
		err := rows.Scan(
			&stats.ID,
			&stats.MetricName,
			&stats.MetricValue,
			&stats.MetricType,
			&stats.Labels,
			&stats.Timestamp,
		)
		if err != nil {
			logrus.WithError(err).Error("Failed to scan system stats")
			return nil, fmt.Errorf("failed to scan system stats: %w", err)
		}
		statsList = append(statsList, stats)
	}

	return statsList, nil
}

// UpdateMetricValue updates the value of a metric
func (r *SystemStatsRepository) UpdateMetricValue(metricName string, value float64) error {
	query := `
		UPDATE system_stats
		SET metric_value = $2, timestamp = $3
		WHERE metric_name = $1
		ORDER BY timestamp DESC
		LIMIT 1
	`

	result, err := r.db.Exec(query, metricName, value, time.Now())
	if err != nil {
		logrus.WithError(err).Error("Failed to update metric value")
		return fmt.Errorf("failed to update metric value: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("metric not found: %s", metricName)
	}

	return nil
}

// Delete deletes system stats by ID
func (r *SystemStatsRepository) Delete(id uuid.UUID) error {
	query := "DELETE FROM system_stats WHERE id = $1"

	result, err := r.db.Exec(query, id)
	if err != nil {
		logrus.WithError(err).Error("Failed to delete system stats")
		return fmt.Errorf("failed to delete system stats: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("system stats not found")
	}

	return nil
}

// DeleteOldStats deletes stats older than the specified duration
func (r *SystemStatsRepository) DeleteOldStats(olderThan time.Duration) error {
	cutoffTime := time.Now().Add(-olderThan)
	query := "DELETE FROM system_stats WHERE timestamp < $1"

	result, err := r.db.Exec(query, cutoffTime)
	if err != nil {
		logrus.WithError(err).Error("Failed to delete old system stats")
		return fmt.Errorf("failed to delete old system stats: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	logrus.Infof("Deleted %d old system stats records", rowsAffected)
	return nil
}
