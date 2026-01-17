-- DiSensor Referral System
-- Run this SQL in Supabase SQL Editor to enable referral tracking

-- 1. Create referrals table to track relationships
CREATE TABLE IF NOT EXISTS referrals (
  id SERIAL PRIMARY KEY,
  referrer_code TEXT NOT NULL,           -- The 6-char code of the inviter
  referee_device_id TEXT NOT NULL,       -- Device ID of the person who was invited
  referee_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  bonus_applied BOOLEAN DEFAULT FALSE,   -- Whether the referral bonus was given
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Prevent duplicate referrals from same device
  UNIQUE(referee_device_id)
);

-- 2. Create indexes
CREATE INDEX IF NOT EXISTS idx_referrals_code ON referrals(referrer_code);
CREATE INDEX IF NOT EXISTS idx_referrals_referee ON referrals(referee_device_id);

-- 3. Enable RLS
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
CREATE POLICY "Anyone can insert referral" ON referrals
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view own referrals" ON referrals
  FOR SELECT USING (
    referee_user_id = auth.uid() OR 
    referrer_code = UPPER(LEFT(auth.uid()::text, 6))
  );

-- 5. Create RPC function to verify and record referral code
CREATE OR REPLACE FUNCTION verify_referral_code(
  p_code TEXT,
  p_device_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_code TEXT;
  v_existing RECORD;
  v_is_self_referral BOOLEAN;
BEGIN
  -- Normalize code to uppercase
  v_code := UPPER(TRIM(p_code));
  
  -- Validate format (6 alphanumeric characters)
  IF LENGTH(v_code) != 6 OR v_code !~ '^[A-Z0-9]{6}$' THEN
    RETURN jsonb_build_object('success', false, 'error', 'INVALID_FORMAT');
  END IF;
  
  -- Check for self-referral (device ID starts with code)
  v_is_self_referral := UPPER(LEFT(p_device_id, 6)) = v_code;
  IF v_is_self_referral THEN
    RETURN jsonb_build_object('success', false, 'error', 'SELF_REFERRAL');
  END IF;
  
  -- Check if this device already has a referral
  SELECT * INTO v_existing FROM referrals WHERE referee_device_id = p_device_id;
  IF FOUND THEN
    RETURN jsonb_build_object(
      'success', false, 
      'error', 'ALREADY_REFERRED',
      'existing_code', v_existing.referrer_code
    );
  END IF;
  
  -- Record the referral
  INSERT INTO referrals (referrer_code, referee_device_id, referee_user_id)
  VALUES (v_code, p_device_id, auth.uid());
  
  RETURN jsonb_build_object('success', true, 'code', v_code);
  
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- 6. Create function to count referrals for a code (for leaderboards/rewards)
CREATE OR REPLACE FUNCTION get_referral_count(p_code TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (
    SELECT COUNT(*) FROM referrals 
    WHERE referrer_code = UPPER(TRIM(p_code))
  );
END;
$$;

-- 7. Comments
COMMENT ON TABLE referrals IS 'Tracks referral relationships between users';
COMMENT ON FUNCTION verify_referral_code IS 'Validates and records a referral code for a device';
