# Pep Education — Master Prompt

Usa este documento al inicio de cada sesión para recordar el contexto completo del proyecto.

---

## Proyecto

**Pep Education** — App de control de peso y salud.
- Admin web: Next.js 14, desplegado en Netlify
- App móvil v1 (`mobile/`): Expo 54 + expo-router, para desarrollo y simulador
- App móvil v2 (`store/`): misma base de código, configurada para App Store + Play Store
- Backend: Supabase (PostgreSQL + Auth + RLS)

**Root local:** `/Users/marco/Proyectos/Pep/`

```
Pep/
├── admin/    → Web admin (Next.js 16 + Tailwind, Vercel)
├── mobile/   → App Expo (iOS/Android)
└── docs/     → Documentación adicional
```

---

## Stack técnico

| Capa | Tecnología |
|------|-----------|
| Backend | Supabase (PostgreSQL + Auth + RLS) |
| Mobile | Expo 54, expo-router, React Native, TypeScript |
| Web Admin | Next.js 14 (App Router), Tailwind CSS |
| Iconos | MaterialCommunityIcons — NUNCA emoji en Text RN |
| Auth | Supabase email+password + confirmación OTP 6 dígitos |
| Store dist | EAS Build + EAS Submit |

**Colores de marca:**
- Morado oscuro: `#7B2D8B`
- Morado medio: `#C4A2DC`
- Morado claro: `#F4EDF8` (fondo)
- Amarillo CTA: `#FFD700`

---

## Supabase

- **Project ID:** `mpdpbfaorquuqvhawwea`
- **URL:** `https://mpdpbfaorquuqvhawwea.supabase.co`
- **Anon key:** en `mobile/.env` y `store/eas.json`

### Tablas

**profiles**
```sql
id uuid PK
auth_uid uuid FK → auth.users
full_name text
email text
phone text
sex text
age integer          -- NO birth_date
height_cm numeric
initial_weight_kg numeric
current_weight_kg numeric
goal_weight_kg numeric
bmi numeric
bmi_category text
role text            -- 'usuario' (mobile) | 'patient' (admin)
is_active boolean
registration_date date
profile_notes text   -- NO "notes"
```

**measurements**
```sql
id, patient_id FK→profiles.id, weight_kg, measurement_date DATE, notes, photo_url
```

**patient_medications**
```sql
id, patient_id FK→profiles.id, medication_name text, active boolean
-- Una fila por medicamento (soporta multi-select)
```

**calendar_events**
```sql
id, patient_id, title, event_date DATE, notes
-- NO columna event_type
```

### RLS Policies (todas aplicadas)
- profiles: SELECT, INSERT, UPDATE para auth_uid = auth.uid()
- measurements: SELECT, INSERT, UPDATE para pacientes
- patient_medications: SELECT, INSERT para pacientes
- calendar_events: SELECT, INSERT para pacientes

### Config de Auth
- Confirmación de email: ACTIVADA
- Template de email: usar `{{ .Token }}` OTP (NO magic link) — actualizar manualmente en Dashboard → Auth → Email Templates → "Confirm signup"
- `flowType: 'pkce'` NUNCA en React Native (requiere WebCrypto, no disponible en RN)

---

## Reglas críticas de código

### 1. Sin emoji en React Native
iOS simulator renderiza emoji unicode como `[?]`. Usar siempre `MaterialCommunityIcons` de `@expo/vector-icons`.

### 2. Sin flowType:'pkce' en Supabase RN
```ts
// mobile/lib/supabase.ts
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
    // flowType 'pkce' ELIMINADO — requiere WebCrypto, no disponible en RN
  },
});
```

### 3. refreshProfile() SOLO en navegación final
`refreshProfile()` dispara `onAuthStateChange` → `TOKEN_REFRESHED` → `hasProfile=true` → `_layout.tsx` redirige. Si se llama durante el onboarding, la pantalla del IMC desaparece antes de que el usuario la vea.
```ts
// CORRECTO: en el botón "¡Ir a mi panel!"
onPress={async () => {
  await refreshProfile();
  router.replace('/(tabs)');
}}
// MAL: dentro de completeOnboarding() o después de un insert
```

### 4. Filtro de roles en admin
Mobile crea perfiles con `role='usuario'`, admin debe usar `.in()`:
```ts
.in("role", ["patient", "usuario"])  // NO .eq("role", "patient")
```
Aplicar en: usuarios/page.tsx, page.tsx (dashboard), calendario/page.tsx, whatsapp/page.tsx

### 5. Columnas DATE con formato YYYY-MM-DD
```ts
measurement_date: new Date().toISOString().split('T')[0]  // NO full ISO timestamp
```

### 6. Guard TOKEN_REFRESHED en AuthContext
```ts
supabase.auth.onAuthStateChange(async (event, session) => {
  setSession(session);
  setUser(session?.user ?? null);
  if (session?.user) {
    if (event !== 'TOKEN_REFRESHED') {  // Guard obligatorio
      await checkProfile(session.user.id);
    }
  } else {
    setHasProfile(false);
  }
  setIsLoading(false);
});
```

---

## Flujos principales

### Registro
```
signUp() → sin session → pantalla verify.tsx (OTP 6 dígitos)
         → verifyOtp({ email, token, type:'signup' })
         → onAuthStateChange SIGNED_IN → checkProfile() → onboarding
```

### Login
```
signInWithPassword() → onAuthStateChange → hasProfile?
  → true  → /(tabs)
  → false → /(onboarding)
```

### Onboarding (6 pasos)
```
1. Teléfono
2. Peso actual + objetivo
3. Altura
4. Edad
5. Sexo
6. Medicamentos (multi-select, una fila por med en patient_medications)
→ Pantalla IMC (celebración) → botón "¡Ir a mi panel!" → refreshProfile() → /(tabs)
```

---

## Estructura de archivos clave

```
mobile/
├── app/
│   ├── (auth)/
│   │   ├── _layout.tsx       — Stack con verify y callback
│   │   ├── login.tsx         — signInWithPassword, manejo "email not confirmed"
│   │   ├── register.tsx      — signUp, sin emailRedirectTo, ruta a verify
│   │   ├── verify.tsx        — 6 cajas OTP, verifyOtp, reenvío
│   │   └── callback.tsx      — deep link handler (pepeducation://auth/callback)
│   ├── (onboarding)/
│   │   └── index.tsx         — 6 pasos, multi-select meds, refreshProfile en botón final
│   ├── (tabs)/
│   │   ├── index.tsx         — Home/Dashboard
│   │   ├── progress.tsx      — Progreso
│   │   ├── calendar.tsx      — Calendario
│   │   └── weight.tsx        — Registro de peso
│   └── _layout.tsx           — Root layout con AuthContext
├── context/
│   └── AuthContext.tsx       — session, user, hasProfile, refreshProfile(), TOKEN_REFRESHED guard
├── lib/
│   └── supabase.ts           — createClient sin flowType:'pkce'
└── constants/
    └── theme.ts              — Colors con lilacDark, lilacMedium, yellow, etc.

admin/
└── src/app/
    ├── page.tsx              — Dashboard (Admin role)
    ├── usuarios/page.tsx     — Lista pacientes
    ├── calendario/page.tsx   — Agenda
    └── whatsapp/page.tsx     — Notificaciones

store/                        — Copia de mobile para tiendas
├── app.json                  — bundleIdentifier: com.pepeducation.app
│                               package: com.pepeducation.app
└── eas.json                  — Perfiles development/preview/production + submit config
```

---

## store/ — Versión para tiendas

`store/app.json` — config adicional vs `mobile/app.json`:
```json
{
  "expo": {
    "ios": {
      "bundleIdentifier": "com.pepeducation.app",
      "buildNumber": "1"
    },
    "android": {
      "package": "com.pepeducation.app",
      "versionCode": 1
    }
  }
}
```

`store/eas.json` — llenar estos campos pendientes:
- `EXPO_APPLE_ID`: tu Apple ID (email)
- `ascAppId`: App Store Connect App ID
- `appleTeamId`: Apple Developer Team ID
- `google-play-key.json`: ruta al JSON de service account de Google Play

Comandos para subir a tiendas:
```bash
# iOS
cd store && eas build --platform ios --profile production
eas submit --platform ios --latest

# Android
cd store && eas build --platform android --profile production
eas submit --platform android --latest
```

---

## Pasos manuales pendientes

1. **Supabase email template** — Dashboard → Authentication → Email Templates → "Confirm signup":
   Cambiar el template para que use `{{ .Token }}` (código OTP de 6 dígitos) en lugar del magic link.
   Ejemplo de template:
   ```
   Tu código de verificación es: {{ .Token }}
   Válido por 10 minutos.
   ```

2. **store/eas.json** — Rellenar Apple ID, App Store Connect App ID, Apple Team ID, y configurar Google Play service account.

3. **Apple Developer Program** — Necesario para subir a App Store ($99/año).

4. **Google Play Console** — Necesario para subir a Play Store ($25 único).

---

## Diagnóstico con Supabase MCP

En sesiones futuras, usar las herramientas MCP de Supabase para:
```
mcp__claude_ai_Supabase__get_logs     — Ver logs de auth, email, errores
mcp__claude_ai_Supabase__execute_sql  — Consultar/modificar datos
mcp__claude_ai_Supabase__apply_migration — Aplicar cambios de schema
```

Project ID Supabase: `mpdpbfaorquuqvhawwea`

---

## Estado actual (sesión 2026-03-30)

Todo funciona excepto los pasos manuales pendientes arriba:
- Iconos: todos los emoji reemplazados con MaterialCommunityIcons en todos los screens
- Onboarding: multi-select medicamentos, IMC celebración no desaparece
- Auth: OTP flow funciona, guard TOKEN_REFRESHED en AuthContext
- Admin: filtro de roles corregido, usuarios aparecen
- store/: carpeta creada con config para App Store + Play Store
