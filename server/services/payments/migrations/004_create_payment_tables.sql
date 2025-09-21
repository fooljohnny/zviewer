-- Create payment_methods table
CREATE TABLE IF NOT EXISTS payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('card', 'bank_account', 'paypal')),
    last4 VARCHAR(4) NOT NULL,
    brand VARCHAR(20),
    exp_month INTEGER CHECK (exp_month >= 1 AND exp_month <= 12),
    exp_year INTEGER CHECK (exp_year >= EXTRACT(YEAR FROM NOW())),
    is_default BOOLEAN DEFAULT FALSE,
    stripe_payment_method_id VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create payments table
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount BIGINT NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'USD' CHECK (currency IN ('USD', 'EUR', 'GBP', 'CAD')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded', 'cancelled')),
    payment_method_id UUID REFERENCES payment_methods(id) ON DELETE SET NULL,
    transaction_id VARCHAR(255),
    description TEXT NOT NULL CHECK (length(description) > 0 AND length(description) <= 500),
    metadata JSONB,
    refunded_amount BIGINT DEFAULT 0 CHECK (refunded_amount >= 0 AND refunded_amount <= amount),
    refund_reason TEXT CHECK (length(refund_reason) <= 500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create subscriptions table
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'past_due')),
    current_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    current_period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    stripe_subscription_id VARCHAR(255) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CHECK (current_period_end > current_period_start)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON payment_methods(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_type ON payment_methods(type);
CREATE INDEX IF NOT EXISTS idx_payment_methods_is_default ON payment_methods(is_default);
CREATE INDEX IF NOT EXISTS idx_payment_methods_stripe_id ON payment_methods(stripe_payment_method_id);

CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_currency ON payments(currency);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at);
CREATE INDEX IF NOT EXISTS idx_payments_payment_method_id ON payments(payment_method_id);
CREATE INDEX IF NOT EXISTS idx_payments_transaction_id ON payments(transaction_id);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan_id ON subscriptions(plan_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_current_period_end ON subscriptions(current_period_end);
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_id ON subscriptions(stripe_subscription_id);

-- Create composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_default ON payment_methods(user_id, is_default) WHERE is_default = TRUE;
CREATE INDEX IF NOT EXISTS idx_payments_user_status ON payments(user_id, status);
CREATE INDEX IF NOT EXISTS idx_payments_user_created ON payments(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_status ON subscriptions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status_period ON subscriptions(status, current_period_end);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_payment_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to automatically update updated_at
CREATE TRIGGER trigger_update_payment_methods_updated_at
    BEFORE UPDATE ON payment_methods
    FOR EACH ROW
    EXECUTE FUNCTION update_payment_updated_at();

CREATE TRIGGER trigger_update_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_payment_updated_at();

CREATE TRIGGER trigger_update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_payment_updated_at();

-- Create function to ensure only one default payment method per user
CREATE OR REPLACE FUNCTION ensure_single_default_payment_method()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default = TRUE THEN
        -- Unset all other default payment methods for this user
        UPDATE payment_methods 
        SET is_default = FALSE 
        WHERE user_id = NEW.user_id AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to ensure only one default payment method per user
CREATE TRIGGER trigger_ensure_single_default_payment_method
    BEFORE INSERT OR UPDATE ON payment_methods
    FOR EACH ROW
    EXECUTE FUNCTION ensure_single_default_payment_method();

-- Create view for active payment methods with user names
CREATE OR REPLACE VIEW active_payment_methods AS
SELECT 
    pm.*,
    u.username as user_name,
    CASE 
        WHEN pm.type = 'card' AND pm.exp_month IS NOT NULL AND pm.exp_year IS NOT NULL THEN
            CASE 
                WHEN EXTRACT(YEAR FROM NOW()) > pm.exp_year OR 
                     (EXTRACT(YEAR FROM NOW()) = pm.exp_year AND EXTRACT(MONTH FROM NOW()) > pm.exp_month) THEN TRUE
                ELSE FALSE
            END
        ELSE FALSE
    END as is_expired,
    CASE 
        WHEN pm.type = 'card' AND pm.exp_month IS NOT NULL AND pm.exp_year IS NOT NULL THEN
            CASE 
                WHEN EXTRACT(YEAR FROM NOW()) = pm.exp_year AND EXTRACT(MONTH FROM NOW()) = pm.exp_month THEN TRUE
                ELSE FALSE
            END
        ELSE FALSE
    END as expires_soon
FROM payment_methods pm
JOIN users u ON pm.user_id = u.id;

-- Create view for payment statistics
CREATE OR REPLACE VIEW payment_stats AS
SELECT 
    COUNT(*) as total_payments,
    SUM(amount) as total_amount,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_payments,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_payments,
    COUNT(CASE WHEN status = 'refunded' THEN 1 END) as refunded_payments,
    AVG(CASE WHEN status = 'completed' THEN amount END) as average_amount,
    COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as payments_today,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as payments_this_week,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as payments_this_month
FROM payments;

-- Create view for subscription statistics
CREATE OR REPLACE VIEW subscription_stats AS
SELECT 
    COUNT(*) as total_subscriptions,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_subscriptions,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_subscriptions,
    COUNT(CASE WHEN status = 'expired' THEN 1 END) as expired_subscriptions,
    COUNT(CASE WHEN status = 'past_due' THEN 1 END) as past_due_subscriptions,
    COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as subscriptions_today,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as subscriptions_this_week,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as subscriptions_this_month
FROM subscriptions;

-- Create view for user payment statistics
CREATE OR REPLACE VIEW user_payment_stats AS
SELECT 
    p.user_id,
    u.username as user_name,
    COUNT(*) as total_payments,
    SUM(p.amount) as total_amount,
    COUNT(CASE WHEN p.status = 'completed' THEN 1 END) as completed_payments,
    MAX(p.created_at) as last_payment_at
FROM payments p
JOIN users u ON p.user_id = u.id
GROUP BY p.user_id, u.username;

-- Create view for user subscription statistics
CREATE OR REPLACE VIEW user_subscription_stats AS
SELECT 
    s.user_id,
    u.username as user_name,
    COUNT(*) as total_subscriptions,
    COUNT(CASE WHEN s.status = 'active' THEN 1 END) as active_subscriptions,
    MAX(s.created_at) as last_subscription_at
FROM subscriptions s
JOIN users u ON s.user_id = u.id
GROUP BY s.user_id, u.username;
