-- Migration: Create payouts table with UUID schema
CREATE TABLE IF NOT EXISTS payouts (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    amount DECIMAL(12,2) NOT NULL,
    method TEXT NOT NULL,
    reference_id TEXT,
    notes TEXT,
    processed_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Remove legacy columns if exist
ALTER TABLE payouts DROP COLUMN IF EXISTS transaction_ref;
ALTER TABLE payouts DROP COLUMN IF EXISTS status;
ALTER TABLE payouts DROP COLUMN IF EXISTS receipt_url;
ALTER TABLE payouts DROP COLUMN IF EXISTS created_by;
