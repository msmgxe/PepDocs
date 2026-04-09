-- ============================================================
-- CALENDAR EVENTS v2 — Migration
-- Ejecutar en Supabase SQL Editor (proyecto mpdpbfaorquuqvhawwea)
-- ============================================================

-- 1. Hacer patient_id nullable (citas del admin sin paciente asignado)
ALTER TABLE public.calendar_events
  ALTER COLUMN patient_id DROP NOT NULL;

-- 2. Cambiar event_date a timestamptz para almacenar hora
ALTER TABLE public.calendar_events
  ALTER COLUMN event_date TYPE timestamptz USING event_date::timestamptz;

-- 3. Agregar columna event_type si no existe
ALTER TABLE public.calendar_events
  ADD COLUMN IF NOT EXISTS event_type text DEFAULT 'Presencial';

-- 4. Agregar columna color si no existe
ALTER TABLE public.calendar_events
  ADD COLUMN IF NOT EXISTS color text DEFAULT '#7B2D8B';

-- 5. Corregir política INSERT: permitir que admin inserte eventos
DROP POLICY IF EXISTS "calendar_insert" ON public.calendar_events;
CREATE POLICY "calendar_insert" ON public.calendar_events
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE auth_uid = auth.uid() AND role = 'admin')
    OR patient_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
  );

-- 6. Corregir política UPDATE: permitir que admin actualice
DROP POLICY IF EXISTS "calendar_update" ON public.calendar_events;
CREATE POLICY "calendar_update" ON public.calendar_events
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE auth_uid = auth.uid() AND role = 'admin')
    OR patient_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
  );

-- 7. Agregar política DELETE (faltaba completamente)
DROP POLICY IF EXISTS "calendar_delete" ON public.calendar_events;
CREATE POLICY "calendar_delete" ON public.calendar_events
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE auth_uid = auth.uid() AND role = 'admin')
    OR patient_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
  );
