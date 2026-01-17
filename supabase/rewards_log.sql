-- DiSensor Rewards Log Table
-- Run this SQL in Supabase SQL Editor to create the rewards_log table

-- 1. Create the rewards_log table
CREATE TABLE IF NOT EXISTS rewards_log (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  device_id TEXT NOT NULL,
  item TEXT NOT NULL,
  cost_qbit INTEGER NOT NULL,
  email TEXT NOT NULL,
  status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'REJECTED')),
  admin_notes TEXT,
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_rewards_log_user_id ON rewards_log(user_id);
CREATE INDEX IF NOT EXISTS idx_rewards_log_status ON rewards_log(status);
CREATE INDEX IF NOT EXISTS idx_rewards_log_created_at ON rewards_log(created_at DESC);

-- 3. Enable Row Level Security
ALTER TABLE rewards_log ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS Policies

-- Policy: Users can insert their own redemption requests
CREATE POLICY "Users can insert own requests" ON rewards_log
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can view their own requests
CREATE POLICY "Users can view own requests" ON rewards_log
  FOR SELECT 
  USING (auth.uid() = user_id);

-- Policy: Admins can view and update all requests (requires admin role)
-- Note: You'll need to set up an admin check function or use a service role key
-- CREATE POLICY "Admins can manage all requests" ON rewards_log
--   FOR ALL
--   USING (is_admin(auth.uid()));

-- 5. Add helpful comments
COMMENT ON TABLE rewards_log IS 'Tracks user redemption requests for gift cards and rewards';
COMMENT ON COLUMN rewards_log.status IS 'PENDING=new, PROCESSING=admin reviewing, COMPLETED=sent, REJECTED=denied';
COMMENT ON COLUMN rewards_log.cost_qbit IS 'Amount of QBIT tokens deducted for this redemption';
