-- Payroll payouts table for weekly approved balances
CREATE TYPE payout_status AS ENUM ('PENDING', 'APPROVED', 'PAID', 'REJECTED');

CREATE TABLE IF NOT EXISTS payroll_payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    payment_method payment_method NOT NULL,
    account_number TEXT NOT NULL,
    amount_cop NUMERIC(20,2) DEFAULT 0,
    amount_usdt NUMERIC(20,8) DEFAULT 0,
    week_start DATE NOT NULL,
    week_end DATE NOT NULL,
    status payout_status NOT NULL DEFAULT 'APPROVED',
    paid_at TIMESTAMPTZ,
    payment_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payroll_payouts_user ON payroll_payouts(user_id);
CREATE INDEX IF NOT EXISTS idx_payroll_payouts_status ON payroll_payouts(status);
CREATE INDEX IF NOT EXISTS idx_payroll_payouts_week ON payroll_payouts(week_end);

-- Trigger to maintain updated_at
CREATE OR REPLACE FUNCTION set_timestamp_payroll_payouts()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_payroll_payouts_updated_at ON payroll_payouts;
CREATE TRIGGER trg_payroll_payouts_updated_at
    BEFORE UPDATE ON payroll_payouts
    FOR EACH ROW
    EXECUTE FUNCTION set_timestamp_payroll_payouts();
