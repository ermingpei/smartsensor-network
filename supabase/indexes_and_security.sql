-- DiSensor Database Indexes (Minimal Safe Version)
-- Only for tables we created: referrals, rewards_log
-- Run in Supabase SQL Editor

-- =====================================================
-- REFERRALS TABLE (from referrals.sql)
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_referrals_code ON referrals(referrer_code);
CREATE INDEX IF NOT EXISTS idx_referrals_device ON referrals(referee_device_id);

-- =====================================================
-- REWARDS_LOG TABLE (from rewards_log.sql)  
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_rewards_status ON rewards_log(status);
CREATE INDEX IF NOT EXISTS idx_rewards_created ON rewards_log(created_at DESC);

-- Enable RLS
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE rewards_log ENABLE ROW LEVEL SECURITY;

-- Update statistics
ANALYZE referrals;
ANALYZE rewards_log;

-- Done!
