-- Migration: add sex and birth_date columns to profiles
-- Execute in Supabase production dashboard (mpdpbfaorquuqvhawwea)

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS sex        text CHECK (sex IN ('male', 'female')),
  ADD COLUMN IF NOT EXISTS birth_date date;

-- Optional: add comments
COMMENT ON COLUMN profiles.sex        IS 'Biological sex: male | female';
COMMENT ON COLUMN profiles.birth_date IS 'Date of birth for age calculation';
