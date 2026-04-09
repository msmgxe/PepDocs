-- ============================================================
-- PEP EDUCATION — Schema completo
-- Ejecutar en orden en el nuevo proyecto Supabase
-- ============================================================

-- 1. PROFILES
CREATE TABLE IF NOT EXISTS public.profiles (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_uid            uuid UNIQUE,
  full_name           text NOT NULL,
  email               text UNIQUE NOT NULL,
  phone               text,
  sex                 text CHECK (sex = ANY (ARRAY['femenino','masculino'])),
  birth_date          date,
  age                 integer,
  height_cm           numeric,
  initial_weight_kg   numeric,
  current_weight_kg   numeric,
  goal_weight_kg      numeric,
  bmi                 numeric,
  bmi_category        text,
  registration_date   date NOT NULL DEFAULT CURRENT_DATE,
  profile_notes       text CHECK (char_length(profile_notes) <= 250),
  notes               text CHECK (char_length(notes) <= 250),
  is_active           boolean NOT NULL DEFAULT true,
  role                text NOT NULL DEFAULT 'usuario'
                        CHECK (role = ANY (ARRAY['usuario','admin','patient'])),
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

-- 2. MEASUREMENTS
CREATE TABLE IF NOT EXISTS public.measurements (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id        uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  weight_kg         numeric NOT NULL,
  weight_lb         numeric GENERATED ALWAYS AS (round(weight_kg * 2.20462, 1)) STORED,
  measurement_date  date NOT NULL DEFAULT CURRENT_DATE,
  notes             text,
  photo_url         text,
  created_by        uuid,
  created_at        timestamptz NOT NULL DEFAULT now()
);

-- 3. PATIENT_MEDICATIONS
CREATE TABLE IF NOT EXISTS public.patient_medications (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id      uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  medication_name text NOT NULL,
  active          boolean DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT timezone('utc', now())
);

-- 4. CALENDAR_EVENTS
CREATE TABLE IF NOT EXISTS public.calendar_events (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id            uuid REFERENCES public.profiles(id) ON DELETE CASCADE,  -- nullable: admin events without patient
  event_date            timestamptz NOT NULL,                                    -- timestamptz to store time
  title                 text NOT NULL,
  notes                 text,
  reminder_enabled      boolean NOT NULL DEFAULT false,
  reminder_days_before  integer NOT NULL DEFAULT 1
                          CHECK (reminder_days_before = ANY (ARRAY[0,1,2,7])),
  event_type            text DEFAULT 'Presencial',
  color                 text DEFAULT '#7B2D8B',
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now()
);

-- 5. MESSAGES_LOG
CREATE TABLE IF NOT EXISTS public.messages_log (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  message_type  text NOT NULL
                  CHECK (message_type = ANY (ARRAY['recordatorio','sugerencia','felicitacion','personalizado'])),
  message_body  text NOT NULL,
  whatsapp_link text,
  sent_by       uuid,
  sent_at       timestamptz NOT NULL DEFAULT now()
);

-- 6. DOSAGES
CREATE TABLE IF NOT EXISTS public.dosages (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id      uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  medication_name text NOT NULL,
  dose_date       date NOT NULL,
  dose_ml         numeric NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT timezone('utc', now())
);
