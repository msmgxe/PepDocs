-- ============================================================
-- PEP EDUCATION — Row Level Security (RLS)
-- ============================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.profiles           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.measurements       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages_log       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dosages            ENABLE ROW LEVEL SECURITY;

-- ---- PROFILES ----
CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT USING (auth.uid() = auth_uid);

CREATE POLICY "profiles_insert" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = auth_uid);

CREATE POLICY "profiles_update" ON public.profiles
  FOR UPDATE USING (auth.uid() = auth_uid);

-- Admin puede ver todos
CREATE POLICY "profiles_admin_select" ON public.profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.auth_uid = auth.uid() AND p.role = 'admin'
    )
  );

-- ---- MEASUREMENTS ----
CREATE POLICY "measurements_select" ON public.measurements
  FOR SELECT USING (
    patient_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
    OR EXISTS (SELECT 1 FROM public.profiles WHERE auth_uid = auth.uid() AND role = 'admin')
  );

CREATE POLICY "measurements_insert" ON public.measurements
  FOR INSERT WITH CHECK (
    patient_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
    OR EXISTS (SELECT 1 FROM public.profiles WHERE auth_uid = auth.uid() AND role = 'admin')
  );

CREATE POLICY "measurements_update" ON public.measurements
  FOR UPDATE USING (
    patient_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
    OR EXISTS (SELECT 1 FROM public.profiles WHERE auth_uid = auth.uid() AND role = 'admin')
  );

-- ---- PATIENT_MEDICATIONS ----
CREATE POLICY "medications_select" ON public.patient_medications
  FOR SELECT USING (
    patient_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
    OR EXISTS (SELECT 1 FROM public.profiles WHERE auth_uid = auth.uid() AND role = 'admin')
  );

CREATE POLICY "medications_insert" ON public.patient_medications
  FOR INSERT WITH CHECK (
    patient_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
  );

-- ---- CALENDAR_EVENTS ----
CREATE POLICY "calendar_select" ON public.calendar_events
  FOR SELECT USING (
    patient_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
    OR EXISTS (SELECT 1 FROM public.profiles WHERE auth_uid = auth.uid() AND role = 'admin')
  );

CREATE POLICY "calendar_insert" ON public.calendar_events
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE auth_uid = auth.uid() AND role = 'admin')
    OR patient_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
  );

CREATE POLICY "calendar_update" ON public.calendar_events
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE auth_uid = auth.uid() AND role = 'admin')
    OR patient_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
  );

CREATE POLICY "calendar_delete" ON public.calendar_events
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE auth_uid = auth.uid() AND role = 'admin')
    OR patient_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
  );

-- ---- MESSAGES_LOG ----
CREATE POLICY "messages_select" ON public.messages_log
  FOR SELECT USING (
    patient_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
    OR EXISTS (SELECT 1 FROM public.profiles WHERE auth_uid = auth.uid() AND role = 'admin')
  );

CREATE POLICY "messages_insert" ON public.messages_log
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE auth_uid = auth.uid() AND role = 'admin')
  );

-- ---- DOSAGES ----
CREATE POLICY "dosages_select" ON public.dosages
  FOR SELECT USING (
    patient_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
    OR EXISTS (SELECT 1 FROM public.profiles WHERE auth_uid = auth.uid() AND role = 'admin')
  );

CREATE POLICY "dosages_insert" ON public.dosages
  FOR INSERT WITH CHECK (
    patient_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
    OR EXISTS (SELECT 1 FROM public.profiles WHERE auth_uid = auth.uid() AND role = 'admin')
  );
