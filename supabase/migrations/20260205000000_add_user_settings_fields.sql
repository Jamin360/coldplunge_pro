-- Add user settings fields to user_profiles table
-- Migration to support user preferences for temperature unit, soundscape volume, and haptics

ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS temp_unit VARCHAR(1) DEFAULT 'F' CHECK (temp_unit IN ('F', 'C')),
ADD COLUMN IF NOT EXISTS soundscape_volume INT DEFAULT 70 CHECK (soundscape_volume BETWEEN 0 AND 100),
ADD COLUMN IF NOT EXISTS haptics_enabled BOOLEAN DEFAULT true;

-- Add comments for documentation
COMMENT ON COLUMN user_profiles.temp_unit IS 'Temperature unit preference: F (Fahrenheit) or C (Celsius)';
COMMENT ON COLUMN user_profiles.soundscape_volume IS 'Soundscape volume level (0-100)';
COMMENT ON COLUMN user_profiles.haptics_enabled IS 'Whether haptic feedback is enabled';

-- Update existing users to have default values (already handled by DEFAULT clause above)
