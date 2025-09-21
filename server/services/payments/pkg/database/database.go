package database

import (
	"database/sql"
	"fmt"
	"time"

	_ "github.com/lib/pq"
	"github.com/sirupsen/logrus"
)

// Connect establishes a connection to the PostgreSQL database
func Connect(databaseURL string) (*sql.DB, error) {
	db, err := sql.Open("postgres", databaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to open database connection: %w", err)
	}

	// Test the connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// Set connection pool settings optimized for high concurrency
	db.SetMaxOpenConns(100)  // Increased for high concurrency
	db.SetMaxIdleConns(25)   // Increased idle connections
	db.SetConnMaxLifetime(5 * time.Minute)  // Connection lifetime
	db.SetConnMaxIdleTime(1 * time.Minute)  // Idle connection timeout

	logrus.Info("Database connection established successfully")
	return db, nil
}

// Close closes the database connection
func Close(db *sql.DB) error {
	if db != nil {
		return db.Close()
	}
	return nil
}
