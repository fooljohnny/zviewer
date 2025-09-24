package database

import (
	"database/sql"
	"fmt"

	"zviewer-admin-service/internal/config"

	_ "github.com/lib/pq"
	"github.com/sirupsen/logrus"
)

// Connect establishes a connection to the PostgreSQL database
func Connect(cfg config.DatabaseConfig) (*sql.DB, error) {
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

	logrus.Info("Successfully connected to database")
	return db, nil
}

// Close closes the database connection
func Close(db *sql.DB) {
	if db != nil {
		if err := db.Close(); err != nil {
			logrus.Errorf("Error closing database connection: %v", err)
		} else {
			logrus.Info("Database connection closed")
		}
	}
}
