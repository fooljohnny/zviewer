package repositories

import (
	"database/sql"
	"testing"
	"time"

	"zviewer-payments-service/internal/models"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestPaymentRepository_Create(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	repo := NewPaymentRepository(db)

	payment := &models.Payment{
		ID:              uuid.New().String(),
		UserID:          uuid.New().String(),
		Amount:          1000,
		Currency:        "USD",
		Status:          models.PaymentStatusPending,
		Description:     "Test payment",
		RefundedAmount:  0,
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}

	mock.ExpectExec("INSERT INTO payments").
		WithArgs(payment.ID, payment.UserID, payment.Amount, payment.Currency, payment.Status,
			payment.PaymentMethodID, payment.TransactionID, payment.Description, payment.Metadata,
			payment.RefundedAmount, payment.RefundReason, payment.CreatedAt, payment.UpdatedAt).
		WillReturnResult(sqlmock.NewResult(1, 1))

	err = repo.Create(payment)
	assert.NoError(t, err)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestPaymentRepository_GetByID(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	repo := NewPaymentRepository(db)

	paymentID := uuid.New().String()
	expectedPayment := &models.Payment{
		ID:              paymentID,
		UserID:          uuid.New().String(),
		Amount:          1000,
		Currency:        "USD",
		Status:          models.PaymentStatusCompleted,
		Description:     "Test payment",
		RefundedAmount:  0,
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
		UserName:        "testuser",
	}

	rows := sqlmock.NewRows([]string{
		"id", "user_id", "amount", "currency", "status", "payment_method_id",
		"transaction_id", "description", "metadata", "refunded_amount", "refund_reason",
		"created_at", "updated_at", "user_name",
	}).AddRow(
		expectedPayment.ID, expectedPayment.UserID, expectedPayment.Amount, expectedPayment.Currency,
		expectedPayment.Status, expectedPayment.PaymentMethodID, expectedPayment.TransactionID,
		expectedPayment.Description, expectedPayment.Metadata, expectedPayment.RefundedAmount,
		expectedPayment.RefundReason, expectedPayment.CreatedAt, expectedPayment.UpdatedAt,
		expectedPayment.UserName,
	)

	mock.ExpectQuery("SELECT p.id, p.user_id").
		WithArgs(paymentID).
		WillReturnRows(rows)

	payment, err := repo.GetByID(paymentID)
	assert.NoError(t, err)
	assert.Equal(t, expectedPayment.ID, payment.ID)
	assert.Equal(t, expectedPayment.UserID, payment.UserID)
	assert.Equal(t, expectedPayment.Amount, payment.Amount)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestPaymentRepository_UpdateStatus(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	repo := NewPaymentRepository(db)

	paymentID := uuid.New().String()
	status := models.PaymentStatusCompleted

	mock.ExpectExec("UPDATE payments").
		WithArgs(status, sqlmock.AnyArg(), paymentID).
		WillReturnResult(sqlmock.NewResult(0, 1))

	err = repo.UpdateStatus(paymentID, status)
	assert.NoError(t, err)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestPaymentRepository_AddRefund(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	repo := NewPaymentRepository(db)

	paymentID := uuid.New().String()
	amount := int64(500)
	reason := "Test refund"

	mock.ExpectExec("UPDATE payments").
		WithArgs(amount, reason, sqlmock.AnyArg(), paymentID).
		WillReturnResult(sqlmock.NewResult(0, 1))

	err = repo.AddRefund(paymentID, amount, reason)
	assert.NoError(t, err)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestPaymentRepository_GetStats(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	repo := NewPaymentRepository(db)

	expectedStats := &models.PaymentStats{
		TotalPayments:     100,
		TotalAmount:       50000,
		CompletedPayments: 90,
		FailedPayments:    5,
		RefundedPayments:  5,
		AverageAmount:     500.0,
		PaymentsToday:     10,
		PaymentsThisWeek:  50,
		PaymentsThisMonth: 100,
	}

	rows := sqlmock.NewRows([]string{
		"total_payments", "total_amount", "completed_payments", "failed_payments",
		"refunded_payments", "average_amount", "payments_today", "payments_this_week", "payments_this_month",
	}).AddRow(
		expectedStats.TotalPayments, expectedStats.TotalAmount, expectedStats.CompletedPayments,
		expectedStats.FailedPayments, expectedStats.RefundedPayments, expectedStats.AverageAmount,
		expectedStats.PaymentsToday, expectedStats.PaymentsThisWeek, expectedStats.PaymentsThisMonth,
	)

	mock.ExpectQuery("SELECT").
		WillReturnRows(rows)

	stats, err := repo.GetStats()
	assert.NoError(t, err)
	assert.Equal(t, expectedStats.TotalPayments, stats.TotalPayments)
	assert.Equal(t, expectedStats.TotalAmount, stats.TotalAmount)
	assert.NoError(t, mock.ExpectationsWereMet())
}
