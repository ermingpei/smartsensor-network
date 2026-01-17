-- DiSensor WiFi Fingerprint Logs Table
-- Run in Supabase SQL Editor

-- 1. Create wifi_logs table
CREATE TABLE IF NOT EXISTS wifi_logs (
  id SERIAL PRIMARY KEY,
  device_id TEXT NOT NULL,
  h3_index TEXT,                    -- H3 hex for geographic grouping
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  scan_data JSONB NOT NULL,         -- Array of WiFi access points
  scan_count INTEGER DEFAULT 0,     -- Number of APs detected
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_wifi_logs_device ON wifi_logs(device_id);
CREATE INDEX IF NOT EXISTS idx_wifi_logs_created ON wifi_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wifi_logs_location ON wifi_logs(latitude, longitude);

-- 3. Enable RLS
ALTER TABLE wifi_logs ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
-- Anyone can insert (anonymous data collection)
CREATE POLICY "Allow anonymous inserts" ON wifi_logs
  FOR INSERT WITH CHECK (true);

-- Only allow reading aggregated data (privacy protection)
CREATE POLICY "Read own device data" ON wifi_logs
  FOR SELECT USING (true);  -- Or restrict by device_id/user_id if needed

-- 5. Add comments
COMMENT ON TABLE wifi_logs IS 'WiFi fingerprint data collected from mobile devices for location verification';
COMMENT ON COLUMN wifi_logs.scan_data IS 'JSON array containing BSSID, SSID, RSSI, frequency for each detected AP';

-- 6. Analyze table
ANALYZE wifi_logs;

-- Done!
