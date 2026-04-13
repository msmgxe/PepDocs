-- Migration: add all potentially missing columns to profiles
-- Execute in Supabase production dashboard:
--   https://supabase.com/dashboard/project/mpdpbfaorquuqvhawwea/sql/new
--
-- Safe to run multiple times (IF NOT EXISTS).

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS target_weight_kg numeric,
  ADD COLUMN IF NOT EXISTS height_cm         numeric,
  ADD COLUMN IF NOT EXISTS sex               text CHECK (sex IN ('male', 'female')),
  ADD COLUMN IF NOT EXISTS birth_date        date;

-- Reload PostgREST schema cache so new columns are visible immediately
NOTIFY pgrst, 'reload schema';
