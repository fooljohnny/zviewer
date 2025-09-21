# Payment Service API Documentation

## Overview

The Payment Service provides secure payment processing, subscription management, and payment method handling for the ZViewer application. It integrates with Stripe for payment processing and maintains PCI compliance standards.

## Base URL

```
http://localhost:8083/api/v1/payments
```

## Authentication

All endpoints (except webhooks) require JWT authentication. Include the JWT token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

## Endpoints

### Payments

#### Create Payment
**POST** `/payments`

Creates a new payment.

**Request Body:**
```json
{
  "amount": 1000,
  "currency": "USD",
  "paymentMethodId": "pm_1234567890",
  "description": "Premium subscription payment",
  "metadata": {
    "subscriptionId": "sub_1234567890"
  }
}
```

**Response:**
```json
{
  "payment": {
    "id": "pay_1234567890",
    "userId": "user_1234567890",
    "amount": 1000,
    "currency": "USD",
    "status": "completed",
    "paymentMethodId": "pm_1234567890",
    "transactionId": "pi_1234567890",
    "description": "Premium subscription payment",
    "metadata": {
      "subscriptionId": "sub_1234567890"
    },
    "createdAt": "2024-01-21T10:00:00Z",
    "updatedAt": "2024-01-21T10:00:00Z"
  }
}
```

#### Get Payment
**GET** `/payments/{id}`

Retrieves a specific payment by ID.

**Response:**
```json
{
  "payment": {
    "id": "pay_1234567890",
    "userId": "user_1234567890",
    "amount": 1000,
    "currency": "USD",
    "status": "completed",
    "paymentMethodId": "pm_1234567890",
    "transactionId": "pi_1234567890",
    "description": "Premium subscription payment",
    "refundedAmount": 0,
    "createdAt": "2024-01-21T10:00:00Z",
    "updatedAt": "2024-01-21T10:00:00Z"
  }
}
```

#### List Payments
**GET** `/payments`

Lists payments with pagination and filtering.

**Query Parameters:**
- `page` (int): Page number (default: 1)
- `limit` (int): Items per page (default: 20, max: 100)
- `status` (string): Filter by status (pending, completed, failed, refunded, cancelled)
- `currency` (string): Filter by currency (USD, EUR, GBP, CAD)
- `dateFrom` (string): Filter by date from (YYYY-MM-DD)
- `dateTo` (string): Filter by date to (YYYY-MM-DD)
- `sortBy` (string): Sort field (default: created_at)
- `sortOrder` (string): Sort order (asc, desc, default: desc)

**Response:**
```json
{
  "payments": [
    {
      "id": "pay_1234567890",
      "userId": "user_1234567890",
      "amount": 1000,
      "currency": "USD",
      "status": "completed",
      "description": "Premium subscription payment",
      "createdAt": "2024-01-21T10:00:00Z",
      "updatedAt": "2024-01-21T10:00:00Z"
    }
  ],
  "total": 1,
  "page": 1,
  "limit": 20,
  "hasMore": false
}
```

#### Process Refund
**POST** `/payments/{id}/refund`

Processes a refund for a payment.

**Request Body:**
```json
{
  "amount": 500,
  "reason": "Customer requested refund"
}
```

**Response:**
```json
{
  "payment": {
    "id": "pay_1234567890",
    "userId": "user_1234567890",
    "amount": 1000,
    "currency": "USD",
    "status": "refunded",
    "refundedAmount": 500,
    "refundReason": "Customer requested refund",
    "createdAt": "2024-01-21T10:00:00Z",
    "updatedAt": "2024-01-21T10:00:00Z"
  }
}
```

#### Delete Payment
**DELETE** `/payments/{id}`

Deletes a payment (soft delete).

**Response:**
```json
{
  "message": "Payment deleted successfully"
}
```

### Subscriptions

#### Create Subscription
**POST** `/subscriptions`

Creates a new subscription.

**Request Body:**
```json
{
  "planId": "plan_1234567890",
  "paymentMethodId": "pm_1234567890",
  "cancelAtPeriodEnd": false
}
```

**Response:**
```json
{
  "subscription": {
    "id": "sub_1234567890",
    "userId": "user_1234567890",
    "planId": "plan_1234567890",
    "status": "active",
    "currentPeriodStart": "2024-01-21T10:00:00Z",
    "currentPeriodEnd": "2024-02-21T10:00:00Z",
    "cancelAtPeriodEnd": false,
    "stripeSubscriptionId": "sub_1234567890",
    "createdAt": "2024-01-21T10:00:00Z",
    "updatedAt": "2024-01-21T10:00:00Z"
  }
}
```

#### Get Subscription
**GET** `/subscriptions/{id}`

Retrieves a specific subscription by ID.

**Response:**
```json
{
  "subscription": {
    "id": "sub_1234567890",
    "userId": "user_1234567890",
    "planId": "plan_1234567890",
    "status": "active",
    "currentPeriodStart": "2024-01-21T10:00:00Z",
    "currentPeriodEnd": "2024-02-21T10:00:00Z",
    "cancelAtPeriodEnd": false,
    "stripeSubscriptionId": "sub_1234567890",
    "createdAt": "2024-01-21T10:00:00Z",
    "updatedAt": "2024-01-21T10:00:00Z"
  }
}
```

#### List Subscriptions
**GET** `/subscriptions`

Lists subscriptions with pagination and filtering.

**Query Parameters:**
- `page` (int): Page number (default: 1)
- `limit` (int): Items per page (default: 20, max: 100)
- `status` (string): Filter by status (active, cancelled, expired, past_due)
- `planId` (string): Filter by plan ID
- `sortBy` (string): Sort field (default: created_at)
- `sortOrder` (string): Sort order (asc, desc, default: desc)

**Response:**
```json
{
  "subscriptions": [
    {
      "id": "sub_1234567890",
      "userId": "user_1234567890",
      "planId": "plan_1234567890",
      "status": "active",
      "currentPeriodStart": "2024-01-21T10:00:00Z",
      "currentPeriodEnd": "2024-02-21T10:00:00Z",
      "cancelAtPeriodEnd": false,
      "createdAt": "2024-01-21T10:00:00Z",
      "updatedAt": "2024-01-21T10:00:00Z"
    }
  ],
  "total": 1,
  "page": 1,
  "limit": 20,
  "hasMore": false
}
```

#### Update Subscription
**PUT** `/subscriptions/{id}`

Updates a subscription.

**Request Body:**
```json
{
  "cancelAtPeriodEnd": true
}
```

**Response:**
```json
{
  "subscription": {
    "id": "sub_1234567890",
    "userId": "user_1234567890",
    "planId": "plan_1234567890",
    "status": "active",
    "currentPeriodStart": "2024-01-21T10:00:00Z",
    "currentPeriodEnd": "2024-02-21T10:00:00Z",
    "cancelAtPeriodEnd": true,
    "stripeSubscriptionId": "sub_1234567890",
    "createdAt": "2024-01-21T10:00:00Z",
    "updatedAt": "2024-01-21T10:00:00Z"
  }
}
```

#### Cancel Subscription
**DELETE** `/subscriptions/{id}`

Cancels a subscription.

**Response:**
```json
{
  "message": "Subscription cancelled successfully"
}
```

### Payment Methods

#### Create Payment Method
**POST** `/payment-methods`

Creates a new payment method.

**Request Body:**
```json
{
  "type": "card",
  "stripePaymentMethodId": "pm_1234567890",
  "isDefault": true
}
```

**Response:**
```json
{
  "paymentMethod": {
    "id": "pm_1234567890",
    "userId": "user_1234567890",
    "type": "card",
    "last4": "4242",
    "brand": "visa",
    "expMonth": 12,
    "expYear": 2025,
    "isDefault": true,
    "stripePaymentMethodId": "pm_1234567890",
    "createdAt": "2024-01-21T10:00:00Z",
    "updatedAt": "2024-01-21T10:00:00Z"
  }
}
```

#### Get Payment Method
**GET** `/payment-methods/{id}`

Retrieves a specific payment method by ID.

**Response:**
```json
{
  "paymentMethod": {
    "id": "pm_1234567890",
    "userId": "user_1234567890",
    "type": "card",
    "last4": "4242",
    "brand": "visa",
    "expMonth": 12,
    "expYear": 2025,
    "isDefault": true,
    "stripePaymentMethodId": "pm_1234567890",
    "isExpired": false,
    "expiresSoon": false,
    "createdAt": "2024-01-21T10:00:00Z",
    "updatedAt": "2024-01-21T10:00:00Z"
  }
}
```

#### List Payment Methods
**GET** `/payment-methods`

Lists payment methods with pagination and filtering.

**Query Parameters:**
- `page` (int): Page number (default: 1)
- `limit` (int): Items per page (default: 20, max: 100)
- `type` (string): Filter by type (card, bank_account, paypal)
- `isDefault` (boolean): Filter by default status
- `sortBy` (string): Sort field (default: created_at)
- `sortOrder` (string): Sort order (asc, desc, default: desc)

**Response:**
```json
{
  "paymentMethods": [
    {
      "id": "pm_1234567890",
      "userId": "user_1234567890",
      "type": "card",
      "last4": "4242",
      "brand": "visa",
      "expMonth": 12,
      "expYear": 2025,
      "isDefault": true,
      "stripePaymentMethodId": "pm_1234567890",
      "isExpired": false,
      "expiresSoon": false,
      "createdAt": "2024-01-21T10:00:00Z",
      "updatedAt": "2024-01-21T10:00:00Z"
    }
  ],
  "total": 1,
  "page": 1,
  "limit": 20,
  "hasMore": false
}
```

#### Update Payment Method
**PUT** `/payment-methods/{id}`

Updates a payment method.

**Request Body:**
```json
{
  "isDefault": true
}
```

**Response:**
```json
{
  "paymentMethod": {
    "id": "pm_1234567890",
    "userId": "user_1234567890",
    "type": "card",
    "last4": "4242",
    "brand": "visa",
    "expMonth": 12,
    "expYear": 2025,
    "isDefault": true,
    "stripePaymentMethodId": "pm_1234567890",
    "createdAt": "2024-01-21T10:00:00Z",
    "updatedAt": "2024-01-21T10:00:00Z"
  }
}
```

#### Delete Payment Method
**DELETE** `/payment-methods/{id}`

Deletes a payment method.

**Response:**
```json
{
  "message": "Payment method deleted successfully"
}
```

#### Get Default Payment Method
**GET** `/payment-methods/default`

Retrieves the default payment method for the user.

**Response:**
```json
{
  "paymentMethod": {
    "id": "pm_1234567890",
    "userId": "user_1234567890",
    "type": "card",
    "last4": "4242",
    "brand": "visa",
    "expMonth": 12,
    "expYear": 2025,
    "isDefault": true,
    "stripePaymentMethodId": "pm_1234567890",
    "createdAt": "2024-01-21T10:00:00Z",
    "updatedAt": "2024-01-21T10:00:00Z"
  }
}
```

#### Set Default Payment Method
**PUT** `/payment-methods/{id}/default`

Sets a payment method as the default for the user.

**Response:**
```json
{
  "message": "Default payment method set successfully"
}
```

### Webhooks

#### Stripe Webhook
**POST** `/webhooks/stripe`

Handles Stripe webhook events. This endpoint does not require authentication as it uses Stripe's webhook signature verification.

**Headers:**
- `Stripe-Signature`: Stripe webhook signature for verification

**Response:**
```json
{
  "status": "success"
}
```

### Statistics (Admin Only)

#### Get Payment Statistics
**GET** `/stats`

Retrieves payment statistics (admin only).

**Response:**
```json
{
  "stats": {
    "totalPayments": 1000,
    "totalAmount": 50000,
    "completedPayments": 950,
    "failedPayments": 30,
    "refundedPayments": 20,
    "averageAmount": 50.0,
    "paymentsToday": 10,
    "paymentsThisWeek": 70,
    "paymentsThisMonth": 300
  }
}
```

## Error Responses

All endpoints may return the following error responses:

### 400 Bad Request
```json
{
  "error": "Invalid request body",
  "details": "Field 'amount' is required"
}
```

### 401 Unauthorized
```json
{
  "error": "Authorization header required"
}
```

### 403 Forbidden
```json
{
  "error": "Access denied"
}
```

### 404 Not Found
```json
{
  "error": "Payment not found"
}
```

### 429 Too Many Requests
```json
{
  "error": "Payment creation rate limit exceeded",
  "retry_after": 60
}
```

### 500 Internal Server Error
```json
{
  "error": "Failed to create payment",
  "details": "Database connection failed"
}
```

## Rate Limiting

Payment creation endpoints are rate limited to prevent abuse:
- **Rate Limit**: 5 requests per minute per user
- **Response**: 429 Too Many Requests with retry_after header

## Security

- All sensitive payment data is stored securely in Stripe
- JWT tokens are required for all authenticated endpoints
- Webhook signatures are verified for Stripe webhooks
- Input validation and sanitization are applied to all requests
- PCI compliance measures are implemented

## Webhook Events

The service handles the following Stripe webhook events:
- `payment_intent.succeeded`
- `payment_intent.payment_failed`
- `payment_intent.canceled`
- `payment_method.attached`
- `payment_method.detached`
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `invoice.payment_succeeded`
- `invoice.payment_failed`
