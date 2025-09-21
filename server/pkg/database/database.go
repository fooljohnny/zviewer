package database

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"

	"zviewer-server/internal/config"

	_ "github.com/lib/pq"
	"github.com/sirupsen/logrus"
)

// NewConnection creates a new database connection
func NewConnection(cfg config.DatabaseConfig) (*sql.DB, error) {
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		cfg.Host, cfg.Port, cfg.User, cfg.Password, cfg.DBName, cfg.SSLMode)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database connection: %w", err)
	}

	// Test the connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// Set connection pool settings
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)

	return db, nil
}

// RunMigrations runs database migrations
func RunMigrations(cfg config.DatabaseConfig) error {
	db, err := NewConnection(cfg)
	if err != nil {
		return fmt.Errorf("failed to connect to database for migrations: %w", err)
	}
	defer db.Close()

	// Read migration files
	migrationDir := "migrations"
	files, err := filepath.Glob(filepath.Join(migrationDir, "*.sql"))
	if err != nil {
		return fmt.Errorf("failed to read migration files: %w", err)
	}

	for _, file := range files {
		content, err := os.ReadFile(file)
		if err != nil {
			return fmt.Errorf("failed to read migration file %s: %w", file, err)
		}

		if _, err := db.Exec(string(content)); err != nil {
			return fmt.Errorf("failed to execute migration %s: %w", file, err)
		}

		logrus.Infof("Successfully executed migration: %s", file)
	}

	return nil
}

// HealthCheck checks if the database is healthy
func HealthCheck(db *sql.DB) error {
	return db.Ping()
}
