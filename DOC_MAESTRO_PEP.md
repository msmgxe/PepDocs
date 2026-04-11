# Pep Education — Descripción General del Proyecto

## ¿Qué es Pep Education?

Pep Education es una plataforma digital de seguimiento de salud y pérdida de peso orientada a pacientes bajo tratamiento médico con medicamentos como Tirzepatide. El sistema conecta a médicos/nutricionistas (vía panel admin web) con sus pacientes (vía app móvil), permitiendo registrar mediciones, agendar citas, enviar mensajes masivos y analizar el progreso clínico.

---

## Repositorios y Estructura

```
/Pep  (monorepo local, NO monorepo en Git — repos separados)
├── admin/     → Panel de administración web (Next.js)
├── mobile/    → App móvil pacientes (Expo / React Native)
└── docs/      → Esta carpeta — documentación del proyecto
```

**GitHub:** https://github.com/msmgxe/pepeducation-admin *(solo el admin está en GitHub actualmente)*

---

## Tecnologías por capa

### Frontend Web — Admin Panel
| Tecnología | Versión | Uso |
|-----------|---------|-----|
| Next.js | 16.2.1 | Framework web, App Router |
| React | 19.2.4 | UI library |
| TypeScript | ^5 | Tipado estático |
| Tailwind CSS | ^4.2.2 | Estilos utilitarios |
| Lucide React | ^1.7.0 | Iconografía |
| @supabase/supabase-js | ^2.100.1 | Cliente de base de datos y auth |

### Frontend Móvil — App Pacientes
| Tecnología | Versión | Uso |
|-----------|---------|-----|
| Expo | ~54.0.33 | Framework React Native |
| React Native | 0.81.5 | UI nativa iOS/Android |
| Expo Router | ~6.0.23 | Navegación file-based |
| TypeScript | ^5 | Tipado estático |
| @supabase/supabase-js | ^2.100.1 | Cliente de base de datos y auth |
| react-native-chart-kit | ^6.12.0 | Gráficos de progreso |
| react-native-svg | 15.12.1 | SVG para gráficos personalizados |
| react-native-gesture-handler | ~2.28.0 | Gestos táctiles (pinch-zoom) |
| react-native-reanimated | ~4.1.1 | Animaciones fluidas |
| expo-image-picker | ~17.0.10 | Fotos de progreso del paciente |
| @react-native-async-storage/async-storage | 2.2.0 | Persistencia de sesión |

### Backend
| Tecnología | Versión | Uso |
|-----------|---------|-----|
| Supabase | Cloud (Free tier) | PostgreSQL + Auth + Storage |
| PostgreSQL | 15 (managed por Supabase) | Base de datos principal |
| Supabase Auth (GoTrue) | Managed | Autenticación email/password |
| Supabase Storage | Managed | Fotos de pacientes, broadcasts |

### Infraestructura y Deploy
| Servicio | Plan | Uso |
|---------|------|-----|
| Vercel | Hobby (gratis) | Hosting del admin web |
| EAS Build (Expo) | Free tier | Build de apps iOS/Android |
| GitHub | Free | Control de versiones (admin) |

---

## Flujos Principales

### Flujo del Médico/Admin
1. Ingresa a `pepeducation-admin.vercel.app/login`
2. Autenticación con email + password + CAPTCHA matemático
3. Verificación de rol `admin` en tabla `profiles`
4. Accede al dashboard con KPIs: usuarios activos, peso perdido, planes activos
5. Gestiona pacientes, agenda citas, envía broadcasts, analiza progreso Tirzepatide

### Flujo del Paciente (App Móvil)
1. Descarga app desde App Store / Play Store
2. Se registra con email + contraseña + verifica OTP
3. Completa onboarding de 6 pasos: teléfono, peso/meta, altura, edad, sexo, medicamentos
4. Accede a tabs: Home, Registro de Peso, Progreso, Calendario, Soporte
5. Registra peso periódicamente con foto opcional
6. Ve análisis de progreso con gráficos

---

## Modelo de Datos (Tablas Principales)

### `auth.users` (Supabase Auth — no modificar directamente)
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | uuid | ID único del usuario |
| email | text | Email de autenticación |
| encrypted_password | text | Hash bcrypt (gestionado por GoTrue) |
| email_confirmed_at | timestamptz | Fecha de confirmación de email |

### `profiles`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | uuid | PK |
| auth_uid | uuid | FK → auth.users.id |
| full_name | text | Nombre completo |
| phone | text | Teléfono |
| weight | numeric | Peso actual (kg) |
| height | numeric | Altura (cm) |
| age | int | Edad |
| sex | text | Sexo ('M'/'F') |
| medications | text[] | Lista de medicamentos |
| goal_weight | numeric | Peso meta |
| notes | text | Notas del médico |
| role | text | 'patient' o 'admin' |

### `measurements`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | uuid | PK |
| user_id | uuid | FK → profiles.id |
| weight | numeric | Peso registrado (kg) |
| photo_url | text | URL foto de progreso |
| created_at | timestamptz | Fecha del registro |

### `calendar_events`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | uuid | PK |
| user_id | uuid | FK → profiles.id |
| title | text | Título del evento |
| description | text | Descripción |
| event_date | date | Fecha del evento |
| created_at | timestamptz | Fecha de creación |

---

## Colores de Marca

| Color | HEX | Uso |
|-------|-----|-----|
| Purple primary | `#7B2D8B` | Botones, sidebar, elementos destacados |
| Purple mid | `#C4A2DC` | Bordes, elementos secundarios |
| Purple pale | `#F4EDF8` | Fondos suaves |
| Yellow CTA | `#FFD700` | Botones de acción en mobile |
| Dark text | `#1A1A1A` | Texto principal |
| Background | `#F9FAFB` | Fondo general |

---

## Estado Actual del Proyecto (Abril 2026)

- ✅ Admin web desplegado y funcional en Vercel
- ✅ Autenticación admin funcionando (email/password + CAPTCHA)
- ✅ Dashboard con datos reales de Supabase (10 pacientes activos)
- ✅ App móvil con todas las pantallas principales implementadas
- ✅ Supabase configurado con tablas, auth y storage
- ⏳ App móvil pendiente de publicación en App Store y Google Play
- ⏳ Dark mode admin pendiente de implementación completa
- ⏳ FAQ de soporte en mobile (placeholder "en desarrollo")
# Pep Education — Arquitectura del Sistema

## Diagrama General de Arquitectura

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USUARIOS FINALES                            │
├─────────────────────┬───────────────────────────────────────────────┤
│    MÉDICO / ADMIN   │           PACIENTES                           │
│                     │                                               │
│  Browser (Chrome,   │   iPhone (iOS 16+)    Android (API 26+)       │
│  Safari, Edge...)   │                                               │
└─────────┬───────────┴───────────┬───────────────────┬──────────────┘
          │                       │                   │
          │ HTTPS                 │ HTTPS             │ HTTPS
          ▼                       ▼                   ▼
┌─────────────────┐   ┌─────────────────────────────────────────────┐
│                 │   │              APP MÓVIL                      │
│   ADMIN WEB     │   │         (React Native / Expo)               │
│                 │   │                                             │
│  Next.js 16     │   │  Expo Router v6 (file-based navigation)     │
│  App Router     │   │  ├── (auth)/login                           │
│  TypeScript     │   │  ├── (auth)/register                        │
│  Tailwind CSS   │   │  ├── (auth)/verify (OTP)                    │
│  Lucide Icons   │   │  ├── (onboarding)/index (6 pasos)           │
│                 │   │  └── (tabs)/                                 │
│  Páginas:       │   │       ├── index (Home)                      │
│  /              │   │       ├── weight (Gráfico peso)             │
│  /usuarios      │   │       ├── progress (Logros)                 │
│  /calendario    │   │       └── calendar (Citas)                  │
│  /analisis      │   │                                             │
│  /whatsapp      │   │  Estado: EAS Build → App Store / Play Store │
│  /login         │   └──────────────────┬──────────────────────────┘
│                 │                      │
└────────┬────────┘                      │
         │                              │
         │ HTTPS API calls              │ HTTPS API calls
         │ (supabase-js SDK)            │ (supabase-js SDK + AsyncStorage)
         │                              │
         ▼                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         SUPABASE CLOUD                              │
│                  Proyecto: mpdpbfaorquuqvhawwea                     │
│                  Plan: FREE (límites de conexión)                   │
│                                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────┐ │
│  │  GoTrue     │  │ PostgreSQL  │  │       Storage               │ │
│  │  (Auth)     │  │    DB       │  │                             │ │
│  │             │  │             │  │  bucket: patient-photos     │ │
│  │ email+pass  │  │ profiles    │  │  bucket: broadcasts         │ │
│  │ OTP email   │  │ measurements│  │                             │ │
│  │ JWT tokens  │  │ calendar_   │  │  Fotos de progreso          │ │
│  │             │  │   events    │  │  Imágenes de broadcasts     │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
         ▲
         │ Deploy via Git push
         │
┌────────┴────────┐
│     VERCEL      │
│  (Hobby Plan)   │
│                 │
│  Hosting Admin  │
│  Web Next.js    │
│                 │
│  pepeducation-  │
│  admin.vercel   │
│  .app           │
│                 │
│  Env vars:      │
│  NEXT_PUBLIC_   │
│  SUPABASE_URL   │
│  NEXT_PUBLIC_   │
│  SUPABASE_ANON  │
│  _KEY           │
└─────────────────┘

         ┌─────────────────┐
         │   EAS BUILD     │
         │  (Expo Cloud)   │
         │                 │
         │  eas build      │
         │  --platform ios │
         │  --platform     │
         │    android      │
         │                 │
         │  Genera:        │
         │  .ipa (iOS)     │
         │  .aab (Android) │
         └────────┬────────┘
                  │
        ┌─────────┴──────────┐
        ▼                    ▼
┌──────────────┐    ┌──────────────────┐
│  App Store   │    │  Google Play     │
│  Connect     │    │  Console         │
│  (iOS)       │    │  (Android)       │
└──────────────┘    └──────────────────┘
```

---

## Diagrama de Flujo de Autenticación

```
ADMIN WEB                          MOBILE APP
    │                                  │
    │ POST /auth/v1/token              │ POST /auth/v1/signup
    │ {email, password}               │ {email, password, user_metadata}
    │                                  │
    ▼                                  ▼
┌────────────────────────────────────────────┐
│              SUPABASE AUTH (GoTrue)        │
│                                            │
│  1. Verifica credenciales bcrypt           │
│  2. Genera JWT access_token (1h)           │
│  3. Genera refresh_token (60 días)         │
│  4. (Mobile) Envía email OTP verification  │
└──────────────┬─────────────────────────────┘
               │
    ┌──────────┴───────────┐
    ▼                      ▼
ADMIN:                  MOBILE:
Consulta profiles        Persiste tokens en
WHERE auth_uid = user.id AsyncStorage
→ role = 'admin'?        → Redirige a onboarding
→ SÍ: dashboard          → o a tabs (si ya hizo
→ NO: signOut + error      onboarding)
```

---

## Diagrama de Capas de la App Móvil

```
┌─────────────────────────────────────────────────────┐
│                  PRESENTACIÓN                        │
│  Screens (app/*.tsx) — Expo Router file-based        │
│  Estilos: React Native StyleSheet + theme.ts         │
├─────────────────────────────────────────────────────┤
│                   CONTEXTO / ESTADO                  │
│  AuthContext.tsx — session, profile, hasProfile      │
│  useState local — datos de pantallas individuales    │
├─────────────────────────────────────────────────────┤
│                     SERVICIOS                        │
│  lib/supabase.ts — cliente Supabase inicializado     │
│  Queries inline en screens (sin capa de repos)       │
├─────────────────────────────────────────────────────┤
│                    PERSISTENCIA                      │
│  Supabase PostgreSQL — datos de negocio              │
│  AsyncStorage — tokens de sesión                     │
│  Supabase Storage — fotos de progreso                │
└─────────────────────────────────────────────────────┘
```

---

## Diagrama de Capas del Admin Web

```
┌─────────────────────────────────────────────────────┐
│                ENRUTAMIENTO (Next.js)                │
│  app/(auth)/login       → Standalone (sin sidebar)   │
│  app/(app)/...          → Con sidebar + header       │
├─────────────────────────────────────────────────────┤
│               COMPONENTES DE LAYOUT                  │
│  layout/layout-shell.tsx — Client wrapper: sidebar   │
│                            position (flex-row-reverse)│
│  layout/header-bar.tsx  — Búsqueda + notificaciones  │
│                            + preferencias (tamaño,   │
│                            posición panel lateral)   │
│  layout/logout-button.tsx — Cierre de sesión         │
├─────────────────────────────────────────────────────┤
│                PÁGINAS (Client Components)           │
│  page.tsx (dashboard)   calendario/   analisis/      │
│  usuarios/              whatsapp/     login/         │
│                         analisis/ incluye Simulador  │
│                         modal (Tirzepatide SURMOUNT) │
├─────────────────────────────────────────────────────┤
│                    UTILIDADES                        │
│  lib/supabase.ts        lib/utils.ts (cn helper)     │
└─────────────────────────────────────────────────────┘
```

---

## Flujo de Datos — Registro de Peso (Mobile)

```
Usuario (App)
    │
    │ Ingresa peso + foto opcional
    ▼
weight.tsx
    │
    ├─── supabase.storage.upload(photo)  ──→  Storage bucket: patient-photos
    │         ↓ URL pública
    │
    └─── supabase.from('measurements').insert({
              user_id, weight, photo_url, created_at
         })  ──→  PostgreSQL: measurements table
              ↓
    ← Actualiza gráfico SVG local
    ← Actualiza profiles.weight (peso actual)
```

---

## Decisiones de Arquitectura

| Decisión | Elección | Razón |
|----------|----------|-------|
| ORM | Ninguno (supabase-js query builder) | Suficiente para el volumen actual, menos overhead |
| State management | useState + Context | App simple, no justifica Redux/Zustand |
| Charts mobile | SVG puro + react-native-chart-kit | SVG puro para customización total, kit para charts estándar |
| Charts admin | SVG puro inline | Sin dependencias adicionales |
| Auth | Supabase GoTrue | Integrado con la DB, sin costo adicional |
| Styling admin | Tailwind CSS v4 | Utility-first, compatible con Next.js 16 |
| Styling mobile | React Native StyleSheet + theme constants | Nativo, con soporte dark/light mode |
| Routing mobile | Expo Router (file-based) | Consistente con Next.js App Router, deep linking automático |
| Realtime | NO utilizado | No hay necesidad de updates en tiempo real actualmente |
| RLS (Row Level Security) | Básico | Validación adicional en app layer |
# Pep Education — Backend (Supabase)

## Configuración del Proyecto Supabase

| Parámetro | Valor |
|-----------|-------|
| **Project ID** | `mpdpbfaorquuqvhawwea` |
| **Project Name** | PepEducation |
| **Región** | (default Supabase region) |
| **Plan** | FREE (con limitaciones) |
| **Propietario (email)** | `adrian.si.msam@gmail.com` |
| **URL del proyecto** | `https://mpdpbfaorquuqvhawwea.supabase.co` |
| **Anon Key (pública)** | Ver archivo `.env.local` / Vercel env vars |
| **Dashboard** | https://supabase.com/dashboard/project/mpdpbfaorquuqvhawwea |


---

## Limitaciones del Plan Gratuito

| Límite | Free | Pro ($25/mes) |
|--------|------|---------------|
| Base de datos | 500 MB | 8 GB |
| Storage | 1 GB | 100 GB |
| Pausa por inactividad | Sí (7 días) | No |
| Conexiones simultáneas | ~60 | Más |
| Backups | Manual | Diarios automáticos |
| Bandwidth | 5 GB | 250 GB |

**Recomendación futura:** Upgradar a Pro ($25/mes) cuando el proyecto tenga más usuarios activos.

---

## Tablas de Base de Datos

### `auth.users` (Gestionada por Supabase Auth — NO modificar directamente)

```sql
-- Esta tabla es interna de Supabase GoTrue.
-- Para crear/modificar usuarios, usar la API de Auth o el dashboard.
-- NUNCA hacer UPDATE manual del encrypted_password con SQL directo
-- porque GoTrue usa su propio bcrypt y puede no ser compatible.

SELECT id, email, email_confirmed_at, created_at
FROM auth.users;
```

### `public.profiles`

```sql
CREATE TABLE profiles (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_uid        uuid REFERENCES auth.users(id),
  full_name       text,
  phone           text,
  weight          numeric,         -- Peso actual en kg
  height          numeric,         -- Altura en cm
  age             integer,
  sex             text,            -- 'M' o 'F'
  medications     text[],          -- Array: ['Tirzepatide', ...]
  goal_weight     numeric,         -- Peso meta en kg
  notes           text,            -- Notas del médico/admin
  role            text DEFAULT 'patient',  -- 'patient' o 'admin'
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);
```

**Nota importante:** La columna `auth_uid` NO tiene constraint UNIQUE declarado. Para hacer upsert se debe usar IF/ELSE con DO $$ en lugar de ON CONFLICT.

### `public.measurements`

```sql
CREATE TABLE measurements (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES profiles(id),
  weight      numeric NOT NULL,    -- Peso en kg
  photo_url   text,               -- URL del Storage (puede ser null)
  created_at  timestamptz DEFAULT now()
);
```

### `public.calendar_events`

```sql
CREATE TABLE calendar_events (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES profiles(id),
  title       text NOT NULL,
  description text,
  event_date  date NOT NULL,
  created_at  timestamptz DEFAULT now()
);
```

---

## Storage Buckets

| Bucket | Uso | Visibilidad |
|--------|-----|-------------|
| `patient-photos` | Fotos de progreso de pacientes (subidas desde mobile) | Privado (con signed URLs) |
| `broadcasts` | Imágenes adjuntas a mensajes masivos (admin) | Privado |

### Subir foto desde Mobile (ejemplo)
```typescript
const { data, error } = await supabase.storage
  .from('patient-photos')
  .upload(`${userId}/${Date.now()}.jpg`, file, {
    contentType: 'image/jpeg',
    upsert: false,
  });

const { data: urlData } = supabase.storage
  .from('patient-photos')
  .getPublicUrl(data.path);
```

---

## Autenticación

### Email + Password (Admin y Mobile)

```typescript
// Login
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'usuario@email.com',
  password: 'contraseña',
});

// Registro (Mobile)
const { data, error } = await supabase.auth.signUp({
  email,
  password,
  options: {
    data: { full_name: 'Nombre Apellido' }
  }
});

// Logout
await supabase.auth.signOut();
```

### Verificación OTP (Mobile solamente)
```typescript
// Verificar el código de 6 dígitos enviado al email
const { data, error } = await supabase.auth.verifyOtp({
  email,
  token: '123456',
  type: 'signup',
});
```

### Recuperación de Contraseña
```typescript
// Enviar email de recovery (configurar Site URL primero)
await supabase.auth.resetPasswordForEmail(email, {
  redirectTo: 'https://pepeducation-admin.vercel.app',
});

// Una vez redirigido con access_token, actualizar contraseña:
await supabase.auth.updateUser({ password: 'NuevaContraseña' });
```

### Configuración de Site URL (Supabase Dashboard)
```
Authentication → URL Configuration:
  Site URL: https://pepeducation-admin.vercel.app
  Redirect URLs: https://pepeducation-admin.vercel.app/**
```

---

## Políticas RLS (Row Level Security)

> La validación principal se hace en el application layer (el admin verifica `role = 'admin'` antes de mostrar contenido). El RLS de Supabase es básico actualmente.

Política recomendada para `profiles`:
```sql
-- Solo el propio usuario puede ver/editar su perfil
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = auth_uid);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = auth_uid);
```

---

## Queries Frecuentes

### Dashboard admin — contar usuarios activos
```sql
SELECT COUNT(*) FROM profiles WHERE role = 'patient';
```

### Obtener mediciones recientes de un paciente
```sql
SELECT weight, created_at
FROM measurements
WHERE user_id = $1
ORDER BY created_at DESC
LIMIT 10;
```

### Verificar si usuario es admin
```sql
SELECT role FROM profiles
WHERE auth_uid = $1
LIMIT 1;
```

### Crear usuario admin (método correcto vía SQL)
```sql
-- Paso 1: Crear en auth.users
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(), 'authenticated', 'authenticated',
  'admin@email.com', crypt('Password123', gen_salt('bf')),
  now(), '{"provider":"email","providers":["email"]}', '{}',
  now(), now(), '', ''
);

-- Paso 2: Crear perfil admin
-- (usar el ID del usuario recién creado)
INSERT INTO profiles (auth_uid, full_name, role)
VALUES ('UUID-DEL-NUEVO-USUARIO', 'Nombre Admin', 'admin');
```

> ⚠️ **Lección aprendida:** Si se resetea la contraseña con SQL directo y el login falla, usar el flujo oficial de recuperación: Dashboard → Authentication → Users → "Send password recovery". El link redirige a la app donde `supabase.auth.updateUser({ password })` actualiza correctamente.

---

## Variables de Entorno Supabase

```bash
# Para admin web (Next.js) — prefijo NEXT_PUBLIC_ requerido para acceso en browser
NEXT_PUBLIC_SUPABASE_URL=https://mpdpbfaorquuqvhawwea.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon key del proyecto>

# Para mobile (Expo) — en archivo .env (no commitear)
EXPO_PUBLIC_SUPABASE_URL=https://mpdpbfaorquuqvhawwea.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=<anon key del proyecto>

# Service Role Key (NUNCA exponer en frontend — solo para scripts de admin o Edge Functions)
SUPABASE_SERVICE_ROLE_KEY=<service role key>
```

> ⚠️ **Error crítico encontrado en producción:** La variable `NEXT_PUBLIC_SUPABASE_URL` fue ingresada en Vercel con un typo (`mpdpbfaorquqvhawwea` en lugar de `mpdpbfaorquuqvhawwea` — faltaba una `u`). Esto causó `ERR_NAME_NOT_RESOLVED` en todos los llamados de auth. Siempre verificar el Project ID exacto al configurar env vars.

---

## Usuarios de Producción

| Email | Rol | Estado |
|-------|-----|--------|
| `adrian.si.msam@gmail.com` | Propietario cuenta Supabase | Activo |
| `masm.a@outlook.com` | admin (en profiles) | Activo — contraseña: ver con propietario |

---

## MCP Connector (Supabase)

El proyecto tiene integración MCP con Supabase para ejecutar queries directamente desde Claude Code:

```json
// Configuración en claude/settings (MCP server)
{
  "name": "supabase",
  "command": "npx",
  "args": ["@supabase/mcp-server-supabase@latest", "--project-ref", "mpdpbfaorquuqvhawwea"]
}
```
# Pep Education — Admin Web (Next.js + Vercel)

## Información del Proyecto

| Parámetro | Valor |
|-----------|-------|
| **Framework** | Next.js 16.2.1 (App Router) |
| **Runtime** | Node.js 24.x |
| **Lenguaje** | TypeScript 5 |
| **Estilos** | Tailwind CSS 4.2.2 |
| **Deploy** | Vercel (Hobby Plan — gratis) |
| **URL producción** | https://pepeducation-admin.vercel.app |
| **GitHub repo** | https://github.com/msmgxe/pepeducation-admin |
| **Vercel Project ID** | `prj_ION10LpJk14WbOv523RIhgo6eclb` |
| **Vercel Org ID** | `team_BEnERBBIE9R2QUBlV90RjOQ5` |
| **Vercel Project Name** | `pepeducation-admin` |

---

## Estructura de Archivos

```
admin/
├── src/
│   ├── app/
│   │   ├── layout.tsx                 # Root layout (html, body, fonts)
│   │   ├── globals.css                # Estilos globales + Tailwind
│   │   ├── (auth)/                    # Rutas sin sidebar (standalone)
│   │   │   ├── layout.tsx             # Layout vacío: return <>{children}</>
│   │   │   └── login/
│   │   │       └── page.tsx           # Pantalla de login
│   │   └── (app)/                     # Rutas con sidebar (autenticadas)
│   │       ├── layout.tsx             # Sidebar + Header + BottomNav mobile (usa LayoutShell)
│   │       ├── page.tsx               # Dashboard principal
│   │       ├── usuarios/
│   │       │   └── page.tsx           # Lista y gestión de pacientes
│   │       ├── calendario/
│   │       │   └── page.tsx           # Calendario de citas
│   │       ├── analisis/
│   │       │   └── page.tsx           # Análisis clínico Tirzepatide + Simulador modal
│   │       ├── whatsapp/
│   │       │   └── page.tsx           # Broadcasting masivo
│   │       └── update-password/
│   │           └── page.tsx           # Cambio de contraseña (admin)
│   ├── components/
│   │   └── layout/
│   │       ├── layout-shell.tsx       # Client Component: flex container con sidebar position
│   │       ├── header-bar.tsx         # Header: búsqueda, notificaciones, preferencias
│   │       └── logout-button.tsx      # Botón de cierre de sesión
│   └── lib/
│       ├── supabase.ts                # Inicialización cliente Supabase
│       └── utils.ts                   # Helper: cn() para clases Tailwind
├── public/                            # Assets estáticos
├── .env.local                         # Variables de entorno locales (NO commitear)
├── .env.local.example                 # Template sin valores sensibles
├── next.config.ts                     # Configuración de Next.js
├── tailwind.config.ts                 # Configuración de Tailwind (darkMode: 'class')
├── tsconfig.json                      # Configuración TypeScript
└── package.json                       # Dependencias
```

---

## Variables de Entorno

### En desarrollo local (archivo `.env.local`)
```bash
NEXT_PUBLIC_SUPABASE_URL=https://mpdpbfaorquuqvhawwea.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon key del proyecto Supabase>
```

### En Vercel (Settings → Environment Variables)

| Variable | Environments | Descripción |
|----------|-------------|-------------|
| `NEXT_PUBLIC_SUPABASE_URL` | Production, Preview, Development | URL del proyecto Supabase |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Production, Preview, Development | Anon key pública de Supabase |

> ⚠️ **Lección crítica:** Al ingresar `NEXT_PUBLIC_SUPABASE_URL` en Vercel, verificar SIEMPRE que el Project ID sea `mpdpbfaorquuqvhawwea` (con doble `u` antes de la `q`). Un typo aquí causa `ERR_NAME_NOT_RESOLVED` en todos los llamados de auth.

---

## Páginas del Admin

### `/` — Dashboard
- **KPIs:** Total usuarios, Actividad (%), Peso perdido (kg), Planes activos
- **Selector temporal:** Semana / Mes con navegación ←→
- **Tabla:** Usuarios recientes con nombre, peso actual, balance y acciones
- **Alertas dinámicas:** Notificaciones de pacientes con variaciones importantes

### `/usuarios` — Gestión de Pacientes
- Lista paginada de todos los pacientes
- Búsqueda por nombre/email
- Ver detalle: mediciones, notas, historial
- Editar notas del médico

### `/calendario` — Citas y Eventos
- Vista mensual de calendario
- Crear evento modal (título, descripción, fecha, paciente)
- Lista de eventos del día seleccionado

### `/analisis` — Análisis Clínico
- Gráfico de evolución de peso con rangos clínicos de Tirzepatide (SVG puro)
- Comparación peso real vs. curva clínica esperada (SURMOUNT-1)
- Tabla de historial de pesajes
- **Simulador** (botón morado): modal con input de semana, calcula pérdida esperada vs. real y muestra gráfica comparativa SVG interactiva

### `/whatsapp` (Broadcasting) — Mensajes Masivos
- Composición de mensaje de texto
- Adjuntar imagen (sube a bucket `broadcasts` en Storage)
- Seleccionar pacientes destinatarios
- Envío masivo (integración con WhatsApp Business API o simulado)

### `/login` — Autenticación
- Formulario: email + contraseña
- CAPTCHA matemático (generado en cliente, no server-side)
  - Operaciones: suma, resta, multiplicación de 1-9
  - Hydration fix: `useState(null)` + `useEffect(() => setCaptcha(makeCaptcha()), [])`
- Verificación de rol `admin` en tabla `profiles` post-login
- Si no es admin: `signOut()` automático + mensaje de error

---

## Inicialización del Cliente Supabase

```typescript
// admin/src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);
```

---

## Flujo de Deploy

### Deploy automático (rama main → Vercel)
```
git add .
git commit -m "feat: descripción del cambio"
git push origin main
# Vercel detecta el push y despliega automáticamente (~1-2 min)
```

> ⚠️ **Crítico:** El git `user.email` debe estar configurado como la cuenta de GitHub para que Vercel acepte el commit. Si el email local no coincide con ningún usuario de GitHub, Vercel bloquea el deploy con "could not associate the committer with a GitHub user".
>
> Configuración correcta para este repo:
> ```bash
> git config user.email "msmgxe@users.noreply.github.com"
> git config user.name "msmgxe"
> ```

### Deploy manual desde CLI
```bash
# Instalar Vercel CLI primero
npm i -g vercel

# Desde la carpeta admin/
cd admin
vercel --prod
```

### Verificar deploy en Vercel
```bash
vercel ls                    # Lista deployments
vercel logs <deployment-id>  # Ver logs de un deploy
```

---

## Comandos de Desarrollo

```bash
cd admin

# Instalar dependencias
npm install

# Servidor de desarrollo (http://localhost:3000)
npm run dev

# Build de producción (verificar errores antes de pushear)
npm run build

# Linter
npm run lint
```

---

## Configuración Git (para referencia)

```bash
# Remote configurado con token de autenticación
git remote set-url origin https://TOKEN@github.com/msmgxe/pepeducation-admin.git

# Ver remoto actual
git remote -v

# Push normal
git push origin main
```

> **Nota:** El token de GitHub expira. Si el push falla con 401/403, generar nuevo token en GitHub → Settings → Developer Settings → Personal Access Tokens → Tokens (classic) → New token → scope: `repo`.

---

## Vercel — Configuración MCP

El proyecto tiene integración MCP con Vercel para gestionar deployments desde Claude Code:

```json
// Herramientas disponibles vía MCP Vercel:
// - list_deployments: Ver historial de deploys
// - get_deployment: Estado de un deploy específico
// - get_deployment_build_logs: Logs de build
// - get_runtime_logs: Logs de runtime
// - get_project: Info del proyecto
// - list_projects: Todos los proyectos
```

Para autenticarse: usar `mcp__plugin_vercel-plugin_vercel__authenticate` desde Claude Code.

---

## Dependencias del Proyecto Admin

```json
{
  "dependencies": {
    "@supabase/supabase-js": "^2.100.1",  // Cliente Supabase
    "lucide-react": "^1.7.0",             // Iconos SVG
    "next": "16.2.1",                     // Framework
    "react": "19.2.4",
    "react-dom": "19.2.4"
  },
  "devDependencies": {
    "@tailwindcss/postcss": "^4.2.2",
    "@types/node": "^20",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "autoprefixer": "^10.4.27",
    "eslint": "^9",
    "eslint-config-next": "16.2.1",
    "postcss": "^8.5.8",
    "tailwindcss": "^4.2.2",
    "typescript": "^5"
  }
}
```

---

## Credenciales de Acceso al Admin

| Campo | Valor |
|-------|-------|
| **URL** | https://pepeducation-admin.vercel.app/login |
| **Email** | `masm.a@outlook.com` |
| **Contraseña** | `PepAdmin2026` |
| **Rol** | admin |

> ⚠️ Cambiar la contraseña periódicamente por seguridad. Para cambiarla: ingresar al admin, ir a `/update-password`.
# Pep Education — Plan de Despliegue Android

## Estado Actual

| Elemento | Estado |
|----------|--------|
| App funcional en simulador/dispositivo | ✅ Listo |
| Bundle ID configurado | ✅ `com.pepeducation.app` |
| Íconos adaptativos configurados | ✅ foreground, background, monochrome |
| Splash screen configurado | ✅ |
| Permisos declarados | ✅ Cámara, fotos |
| EAS Build configurado | ✅ Perfiles: development, production |
| Cuenta Google Play Console | ❌ Pendiente crear ($25 único) |
| Cuenta EAS (Expo) | ❌ Pendiente crear (gratis) |

---

## Configuración en app.json (Android)

```json
{
  "expo": {
    "android": {
      "package": "com.pepeducation.app",
      "adaptiveIcon": {
        "foregroundImage": "./assets/images/android-icon-foreground.png",
        "backgroundImage": "./assets/images/android-icon-background.png",
        "backgroundColor": "#E6F4FE",
        "monochromeImage": "./assets/images/android-icon-monochrome.png"
      },
      "edgeToEdgeEnabled": true,
      "predictiveBackGestureEnabled": false,
      "permissions": [
        "android.permission.CAMERA",
        "android.permission.READ_EXTERNAL_STORAGE",
        "android.permission.WRITE_EXTERNAL_STORAGE",
        "android.permission.READ_MEDIA_IMAGES"
      ],
      "intentFilters": [
        {
          "action": "VIEW",
          "autoVerify": true,
          "data": [{ "scheme": "pepeducation" }],
          "category": ["BROWSABLE", "DEFAULT"]
        }
      ]
    }
  }
}
```

---

## Configuración EAS (eas.json)

```json
{
  "cli": { "version": ">= 12.0.0" },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "production": {
      "autoIncrement": true
    }
  },
  "submit": {
    "production": {
      "android": {
        "serviceAccountKeyPath": "./google-play-key.json",
        "track": "internal"
      }
    }
  }
}
```

---

## Requisitos Previos

### 1. Cuenta Google Play Console
- **URL:** https://play.google.com/console
- **Costo:** $25 USD (pago único, para siempre)
- **Tiempo de aprobación:** Instantáneo a 48h
- **Requiere:** Cuenta Google (Gmail), tarjeta de crédito/débito

### 2. Cuenta EAS (Expo Application Services)
- **URL:** https://expo.dev
- **Costo:** Gratis (plan Free: 30 builds/mes)
- **Requiere:** Email

### 3. Google Cloud Service Account (para submit automatizado)
- Requerido para que EAS pueda subir el `.aab` automáticamente a Play Store
- Se genera en Google Play Console → Setup → API access → Create service account

---

## Proceso Paso a Paso

### FASE 1 — Configuración de cuentas (Día 1)

#### Paso 1.1 — Crear cuenta EAS
```bash
# Desde la carpeta mobile/
cd /Users/marco/Proyectos/Pep/mobile

# Login o crear cuenta en expo.dev
npx eas login
# Ingresa email y contraseña de expo.dev

# Verificar login
npx eas whoami
```

#### Paso 1.2 — Inicializar EAS en el proyecto
```bash
npx eas init
# Esto crea un projectId en expo.extra.eas.projectId dentro de app.json
# Confirmar que el slug es: PepEducation
```

Después de `eas init`, el `app.json` tendrá:
```json
{
  "expo": {
    "extra": {
      "eas": {
        "projectId": "xxxx-xxxx-xxxx-xxxx"
      }
    }
  }
}
```

#### Paso 1.3 — Crear cuenta Google Play Console
1. Ir a https://play.google.com/console
2. Aceptar el Developer Distribution Agreement
3. Pagar $25 USD con tarjeta
4. Llenar información del desarrollador (nombre real o empresa)
5. Esperar aprobación (usualmente menos de 24h)

#### Paso 1.4 — Crear la app en Google Play Console
1. **All apps → Create app**
2. App name: `Pep Education`
3. Default language: `Español (España)` o `Español (Latinoamérica)`
4. App or Game: **App**
5. Free or Paid: **Free**
6. Declarations: marcar las casillas de política y leyes
7. **Create app**

---

### FASE 2 — Preparar assets del store (Día 1-2)

Los siguientes assets son necesarios para publicar en Google Play:

| Asset | Dimensiones | Formato | Notas |
|-------|-------------|---------|-------|
| Ícono de la app | 512×512 px | PNG (sin transparencia) | El `icon.png` actual debe cumplir esto |
| Feature graphic | 1024×500 px | JPG o PNG | Banner superior en Play Store |
| Capturas de pantalla | mín. 1280×720 o 720×1280 | JPG o PNG | Mínimo 2, máximo 8 |
| Video (opcional) | YouTube URL | - | Trailer de la app |

#### Capturas de pantalla recomendadas:
1. Pantalla de login
2. Dashboard / Home de paciente
3. Gráfico de peso
4. Pantalla de progreso
5. Calendario de citas
6. Pantalla de perfil/onboarding

---

### FASE 3 — Build de producción (Día 2)

```bash
cd /Users/marco/Proyectos/Pep/mobile

# Build para Android (genera .aab)
npx eas build --platform android --profile production

# El proceso tarda ~10-15 minutos en los servidores de EAS
# EAS maneja automáticamente:
#   - Keystore (firma de la app) — lo genera y guarda en la nube
#   - Versión (autoIncrement: true en eas.json)
```

**Primera vez:** EAS preguntará si quieres generar un keystore nuevo o subir uno existente. Elegir **"Generate new keystore"**. EAS lo guarda en su nube asociado a tu cuenta.

> ⚠️ **CRÍTICO:** EAS guarda el keystore en la nube de expo.dev. Si pierdes acceso a esa cuenta, no podrás actualizar la app en Play Store. Guardar las credenciales de expo.dev de forma segura.

Al terminar, EAS proporciona un link para descargar el `.aab`.

---

### FASE 4 — Subir a Google Play (Día 2)

#### Opción A — Submit automatizado con EAS
```bash
# Primero necesitas la Service Account Key de Google
# (google-play-key.json — ver instrucciones abajo)

npx eas submit --platform android --profile production
```

#### Crear Service Account Key (para Opción A):
1. En Play Console → **Setup → API access**
2. Clic en **"Go to Google Cloud Console"**
3. Crear Service Account → dar nombre → rol: "Service Account User"
4. Crear clave JSON → descargar → guardar como `google-play-key.json` en `mobile/`
5. En Play Console → **Setup → API access → Grant access** a la nueva service account
6. Dar permiso: "Release to production, exclude devices, and use Play App Signing"

El archivo `google-play-key.json` está en `.gitignore` — NO subir a GitHub.

#### Opción B — Subir manualmente desde Play Console
1. Play Console → tu app → **Release → Production**
2. **Create new release**
3. Subir el archivo `.aab` descargado de EAS
4. Completar las notas de la versión
5. **Save** → **Review release** → **Start rollout to Production**

---

### FASE 5 — Completar listing en Play Store (Día 2-3)

En Play Console → tu app → **Store presence → Main store listing**:

**Descripción corta** (máx. 80 caracteres):
```
Seguimiento de peso y salud con tu médico — Tirzepatide
```

**Descripción completa** (máx. 4000 caracteres):
```
Pep Education es tu compañero digital para el seguimiento 
de tu tratamiento de pérdida de peso.

Con Pep puedes:
• Registrar tu peso diariamente con fotos de progreso
• Ver tu evolución en gráficos claros y motivadores
• Consultar tus citas médicas en el calendario
• Mantener comunicación directa con tu equipo médico
• Seguir tu tratamiento con Tirzepatide de forma segura

Diseñado para pacientes bajo supervisión médica especializada.
```

**Categoría:** Health & Fitness

**Política de privacidad:** URL obligatoria (crear una página web simple o usar un generador gratuito como privacypolicytemplate.net)

---

### FASE 6 — Revisión y publicación

1. Completar cuestionario de clasificación de contenido
2. Completar la sección de privacidad (Data safety)
   - La app recopila: Peso, fotos, email
   - Los datos son usados para: Seguimiento médico
   - Los datos son compartidos con: El médico del paciente
3. Clic en **"Publish"**

**Tiempo de revisión primera publicación:** 1–7 días hábiles

---

## Actualizar la App (versiones futuras)

```bash
# EAS autoIncrement: true maneja la versión automáticamente
npx eas build --platform android --profile production
npx eas submit --platform android --profile production

# O subir manualmente el .aab a Play Console → Create new release
```

---

## Checklist Final Android

- [ ] Cuenta Google Play Console creada y aprobada ($25)
- [ ] Cuenta EAS creada y logueada
- [ ] `eas init` ejecutado (projectId en app.json)
- [ ] Feature graphic 1024×500 creado
- [ ] Capturas de pantalla preparadas (mín. 2)
- [ ] Política de privacidad con URL pública
- [ ] Build ejecutado: `eas build --platform android --profile production`
- [ ] App subida a Play Console (manual o EAS submit)
- [ ] Store listing completo (descripción, categoría, capturas)
- [ ] Cuestionario de contenido completado
- [ ] Data safety completado
- [ ] App publicada (o en revisión)

---

## Información Técnica del Build

| Parámetro | Valor |
|-----------|-------|
| Package name | `com.pepeducation.app` |
| Min SDK version | Android 26 (Oreo 8.0) — establecido por Expo |
| Target SDK version | Android 35 (Android 15) |
| Build format | `.aab` (Android App Bundle) |
| Arquitecturas | arm64-v8a, armeabi-v7a, x86_64 |
| New Architecture | Habilitada (`newArchEnabled: true`) |
# Pep Education — Plan de Despliegue iOS

## Estado Actual

| Elemento | Estado |
|----------|--------|
| App funcional en simulador iOS | ✅ Listo |
| Bundle Identifier configurado | ✅ `com.pepeducation.app` |
| Ícono configurado | ✅ `./assets/images/icon.png` |
| Splash screen configurado | ✅ |
| Permisos de privacidad (infoPlist) | ❌ Pendiente agregar |
| EAS Build configurado | ✅ Perfil production en eas.json |
| Datos de submit iOS en eas.json | ❌ Pendiente (necesita Apple IDs) |
| Apple Developer Program | ❌ Pendiente ($99/año) |
| App en App Store Connect | ❌ Pendiente crear |

---

## Requisitos Previos

### 1. Apple Developer Program
- **URL:** https://developer.apple.com/programs/enroll/
- **Costo:** $99 USD/año (renovación anual)
- **Tiempo de aprobación:** Inmediato con Apple ID personal; 1–5 días si requiere verificación de identidad (empresa)
- **Requiere:** Apple ID, tarjeta de crédito, número de teléfono verificado

### 2. App Store Connect
- Incluido con Apple Developer Program
- **URL:** https://appstoreconnect.apple.com
- Se accede con el mismo Apple ID del Developer Program

### 3. EAS Build (ya configurado)
- Misma cuenta que para Android

---

## Configuración Pendiente en app.json

Añadir `infoPlist` con los strings de privacidad requeridos por Apple:

```json
{
  "expo": {
    "ios": {
      "supportsTablet": false,
      "bundleIdentifier": "com.pepeducation.app",
      "infoPlist": {
        "NSPhotoLibraryUsageDescription": "Pep necesita acceso a tus fotos para subir tu foto de progreso.",
        "NSCameraUsageDescription": "Pep necesita tu cámara para tomar fotos de progreso.",
        "NSPhotoLibraryAddUsageDescription": "Pep guardará tus fotos de progreso en tu galería.",
        "NSFaceIDUsageDescription": "Pep usa Face ID para proteger tu información de salud."
      },
      "buildNumber": "1"
    }
  }
}
```

> **Nota sobre `supportsTablet`:** Actualmente es `true`. Si la app no está optimizada para iPad (layouts adaptados), se recomienda cambiar a `false` para evitar rechazos en App Review por UI no adaptada.

---

## Configuración EAS para iOS Submit

Actualizar `mobile/eas.json` con datos reales de Apple:

```json
{
  "submit": {
    "production": {
      "ios": {
        "appleId": "TU_EMAIL@icloud.com",
        "ascAppId": "1234567890",
        "appleTeamId": "ABCDE12345"
      }
    }
  }
}
```

**Cómo obtener cada ID:**

| Campo | Dónde encontrarlo |
|-------|-------------------|
| `appleId` | Tu email del Apple Developer Program |
| `ascAppId` | App Store Connect → tu app → URL: `.../apps/XXXXXXXXXX/...` |
| `appleTeamId` | developer.apple.com/account → Membership → Team ID (10 caracteres) |

---

## Proceso Paso a Paso

### FASE 1 — Configuración de cuentas (Día 1)

#### Paso 1.1 — Inscribirse en Apple Developer Program
1. Ir a https://developer.apple.com/programs/enroll/
2. Sign in con Apple ID
3. Elegir: **Individual** (si eres persona natural) o **Organization** (empresa)
4. Completar información personal/empresa
5. Pagar $99 USD con tarjeta o PayPal
6. Esperar confirmación por email (puede ser inmediata o hasta 5 días)

#### Paso 1.2 — Registrar App ID en Apple Developer
1. developer.apple.com → Certificates, Identifiers & Profiles
2. **Identifiers → +**
3. Tipo: **App IDs**
4. Platform: **iOS, iPadOS**
5. Bundle ID: **Explicit** → `com.pepeducation.app`
6. Capabilities: marcar según sea necesario (Push Notifications si se implementa luego)
7. **Register**

#### Paso 1.3 — Crear la app en App Store Connect
1. Ir a https://appstoreconnect.apple.com
2. **My Apps → +** → **New App**
3. Plataformas: **iOS**
4. Name: `Pep Education`
5. Primary Language: **Spanish**
6. Bundle ID: `com.pepeducation.app` (aparece si registraste el App ID)
7. SKU: `pepeducation-001` (ID interno, no se muestra al usuario)
8. User Access: **Full Access**
9. **Create**

---

### FASE 2 — Preparar assets del store (Día 1-2)

Apple tiene requisitos estrictos de capturas de pantalla. Son obligatorias para al menos 2 tamaños de iPhone:

| Dispositivo | Resolución (portrait) | Formato |
|-------------|----------------------|---------|
| iPhone 6.9" (iPhone 16 Pro Max) | 1320×2868 px | JPG o PNG |
| iPhone 6.7" (iPhone 14 Plus) | 1284×2778 px | JPG o PNG |
| iPad Pro 13" (opcional) | 2064×2752 px | JPG o PNG |

**Mínimo obligatorio:** Al menos 3 capturas del iPhone 6.9" o 6.7"

#### Capturas recomendadas:
1. Pantalla de login (branding)
2. Home del paciente (bienvenida + próxima cita)
3. Gráfico de peso (tendencia visual)
4. Pantalla de progreso (logros, badges)
5. Calendario de citas
6. Registro de peso (con cámara)

**Herramientas para crear capturas:**
- Ejecutar en simulador de Xcode → `Cmd+S` para captura
- Usar Figma con device mockups para presentación más profesional

---

### FASE 3 — Configurar app.json y eas.json (Día 2)

```bash
cd /Users/marco/Proyectos/Pep/mobile
```

1. Agregar `infoPlist` en `app.json` (ver configuración arriba)
2. Actualizar `eas.json` con `appleId`, `ascAppId`, `appleTeamId`
3. Commitear los cambios (excepto datos sensibles en .gitignore)

---

### FASE 4 — Build de producción iOS (Día 2-3)

```bash
cd /Users/marco/Proyectos/Pep/mobile

# Build para iOS (genera .ipa)
npx eas build --platform ios --profile production
```

**Primera vez:** EAS preguntará credenciales de Apple para manejar:
- **Provisioning Profile** — permite instalar la app en dispositivos
- **Distribution Certificate** — firma criptográfica de la app
- **App Store Connect API Key** — para subir el build

EAS puede manejar todo automáticamente con las credenciales correctas, o puedes ir a Apple Developer → crear manualmente.

> La primera build puede tardar 20–30 minutos. Las siguientes son más rápidas (~10 min).

**Si EAS pide Apple ID y contraseña:**
- Ingresar el email y contraseña del Apple Developer Program
- Si tienes 2FA activado (obligatorio para Apple Developer), EAS pedirá el código

---

### FASE 5 — Subir a App Store (Día 3)

#### Opción A — Submit automatizado con EAS
```bash
npx eas submit --platform ios --profile production
# EAS sube el .ipa a App Store Connect automáticamente
```

#### Opción B — Subir con Transporter (app de Mac)
1. Descargar **Transporter** de Mac App Store (gratis, de Apple)
2. Iniciar sesión con Apple ID del Developer Program
3. Arrastrar el `.ipa` descargado de EAS al Transporter
4. Clic **Deliver**
5. El build aparecerá en App Store Connect en ~15 minutos

---

### FASE 6 — Completar App Store Connect (Día 3)

En App Store Connect → tu app → **App Store** → **iOS App**:

**Version Information:**
- **Version:** 1.0.0
- **What's New (notas de versión):**
  ```
  Lanzamiento inicial de Pep Education.
  • Registro y seguimiento de peso
  • Gráficos de progreso visual
  • Calendario de citas médicas
  • Comunicación con tu equipo médico
  ```

**App Information:**
- **Category:** Primary: Health & Fitness
- **Content Rights:** ¿Tiene contenido de terceros? No
- **Age Rating:** 4+ (app de salud, sin contenido adulto)

**Pricing and Availability:**
- Price: **Free**
- Available in: Todos los países (o específicos)

**Privacy Policy URL:** Obligatorio (misma que Android — crear página web)

---

### FASE 7 — Cuestionario de Privacidad (App Privacy)

Apple requiere declarar exactamente qué datos recopila la app:

| Tipo de dato | ¿Se recopila? | ¿Vinculado al usuario? | ¿Para qué? |
|-------------|--------------|----------------------|-----------|
| Email | Sí | Sí | Autenticación |
| Peso/medidas de salud | Sí | Sí | Funcionalidad de la app |
| Fotos | Sí (opcional) | Sí | Registro visual de progreso |
| Nombre | Sí | Sí | Identificación |
| Teléfono | Sí | Sí | Contacto médico |

---

### FASE 8 — Build Submission y Review

1. En App Store Connect → **Submit for Review**
2. Responder cuestionario de export compliance (cifrado): **No** (si no usas cifrado propio)
3. Advertising Identifier (IDFA): **No** (si no usas ads)
4. **Submit**

**Tiempo de revisión de Apple:** 24–72 horas (usualmente ~24h para primera versión)

**Posibles rechazos comunes y soluciones:**

| Razón de rechazo | Solución |
|-----------------|----------|
| Falta privacy policy | Agregar URL de política de privacidad |
| Screenshots incorrectas | Asegurarse de usar el tamaño de iPhone 6.9" |
| Permisos sin uso justificado | Verificar que infoPlist tenga descripciones claras |
| App crashes en review | Probar en dispositivo real, no solo simulador |
| Metadata genérica | Personalizar descripción, no usar lorem ipsum |

---

## Actualizar la App (versiones futuras)

```bash
# EAS maneja buildNumber automáticamente con autoIncrement
# Actualizar version en app.json si es cambio mayor
npx eas build --platform ios --profile production
npx eas submit --platform ios --profile production
# → En App Store Connect: agregar nueva versión → submit for review
```

---

## Checklist Final iOS

- [ ] Apple Developer Program pagado y activo ($99/año)
- [ ] App ID registrado: `com.pepeducation.app`
- [ ] App creada en App Store Connect
- [ ] `infoPlist` con strings de privacidad agregado a `app.json`
- [ ] `eas.json` actualizado con `appleId`, `ascAppId`, `appleTeamId`
- [ ] EAS init ejecutado (projectId en app.json)
- [ ] Capturas de pantalla preparadas (iPhone 6.9" obligatorio)
- [ ] Política de privacidad con URL pública
- [ ] Build ejecutado: `eas build --platform ios --profile production`
- [ ] Build subido a App Store Connect (EAS submit o Transporter)
- [ ] Store listing completo (descripción, categoría, capturas)
- [ ] Cuestionario de privacidad completado
- [ ] Cuestionario export compliance completado
- [ ] Submitted for Review
- [ ] App aprobada y publicada

---

## Información Técnica del Build iOS

| Parámetro | Valor |
|-----------|-------|
| Bundle Identifier | `com.pepeducation.app` |
| iOS mínimo | iOS 16 (establecido por Expo 54) |
| Arquitecturas | arm64 (dispositivos), x86_64 (simulador) |
| Build format | `.ipa` |
| New Architecture | Habilitada (`newArchEnabled: true`) |
| Tablet soporte | Configurado (revisar si UI es responsive en iPad) |

---

## Importante: Diferencias iOS vs Android en la App

| Feature | Android | iOS | Notas |
|---------|---------|-----|-------|
| Image picker | `READ_MEDIA_IMAGES` | `NSPhotoLibraryUsageDescription` | Permisos distintos |
| Deep linking | `intentFilters` con `pepeducation://` | `scheme: "pepeducation"` | Ambos configurados |
| Splash screen | `expo-splash-screen` | `expo-splash-screen` | Mismo plugin |
| Push notifications | Firebase (si se agrega) | APNs certificate (si se agrega) | No implementado aún |
| Haptic feedback | `expo-haptics` | `expo-haptics` | Disponible en ambos |
# Pep Education — Cuentas, Credenciales y Parámetros

> ⚠️ **DOCUMENTO CONFIDENCIAL** — No compartir públicamente. No subir a repositorios públicos de GitHub. Guardar copia segura offline (ej: Bitwarden, 1Password, o papel físico en lugar seguro).

---

## Resumen de Cuentas

| Servicio | Email/Usuario | Contraseña | Estado |
|---------|--------------|-----------|--------|
| Supabase (propietario) | `adrian.si.msam@gmail.com` | (propia de Adrian) | ✅ Activo |
| Admin Web (usuario admin) | `masm.a@outlook.com` | `PepAdmin2026` | ✅ Activo |
| Vercel | (cuenta vinculada) | (propia) | ✅ Activo |
| GitHub | `msmgxe` | (propia) | ✅ Activo |
| EAS / expo.dev | ❌ Pendiente crear | - | ⏳ |
| Google Play Console | ❌ Pendiente crear | - | ⏳ |
| Apple Developer Program | ❌ Pendiente crear | - | ⏳ |

---

## Supabase

### Proyecto Principal (PRODUCCIÓN)
| Parámetro | Valor |
|-----------|-------|
| **Project ID** | `mpdpbfaorquuqvhawwea` |
| **Project Name** | PepEducation |
| **URL** | `https://mpdpbfaorquuqvhawwea.supabase.co` |
| **Propietario** | `adrian.si.msam@gmail.com` |
| **Plan** | FREE |
| **Dashboard** | https://supabase.com/dashboard/project/mpdpbfaorquuqvhawwea |

### Keys del Proyecto
| Key | Tipo | Dónde obtenerla |
|-----|------|----------------|
| `anon` key | Pública (safe para frontend) | Supabase → Settings → API → anon public |
| `service_role` key | Privada (NUNCA en frontend) | Supabase → Settings → API → service_role |

> Para ver las keys: Supabase Dashboard → Settings → API → "Project API keys"


---

## Vercel

| Parámetro | Valor |
|-----------|-------|
| **Project Name** | `pepeducation-admin` |
| **Project ID** | `prj_ION10LpJk14WbOv523RIhgo6eclb` |
| **Org/Team ID** | `team_BEnERBBIE9R2QUBlV90RjOQ5` |
| **URL producción** | https://pepeducation-admin.vercel.app |
| **Dashboard** | https://vercel.com/dashboard |
| **Plan** | Hobby (gratis) |
| **Framework detectado** | Next.js |
| **Node version** | 24.x |

### Variables de Entorno en Vercel
| Variable | Environments | Descripción |
|----------|-------------|-------------|
| `NEXT_PUBLIC_SUPABASE_URL` | Production, Preview, Development | `https://mpdpbfaorquuqvhawwea.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Production, Preview, Development | Anon key del proyecto Supabase |

> ⚠️ **Typo histórico:** El valor de `NEXT_PUBLIC_SUPABASE_URL` fue ingresado con un typo una vez (`mpdpbfaorquqvhawwea` sin una `u`). Siempre verificar que tenga exactamente `mpdpbfaorquuqvhawwea`.

---

## GitHub

| Parámetro | Valor |
|-----------|-------|
| **Username** | `msmgxe` |
| **Repositorio admin** | https://github.com/msmgxe/pepeducation-admin |
| **Rama principal** | `main` |
| **Visibilidad** | (revisar si es público o privado) |

### Personal Access Token (GitHub)
- Se genera en: GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
- Scope necesario: `repo` (acceso completo a repositorios)
- Los tokens expiran — si el push falla, generar uno nuevo

Para configurar el remote con token:
```bash
git remote set-url origin https://USUARIO:TOKEN@github.com/msmgxe/pepeducation-admin.git
```

---

## Admin Web — Credenciales de Acceso

| Campo | Valor |
|-------|-------|
| **URL** | https://pepeducation-admin.vercel.app/login |
| **Email** | `masm.a@outlook.com` |
| **Contraseña actual** | `PepAdmin2026` |
| **Rol en DB** | admin |
| **Cómo cambiar contraseña** | Ir a `/update-password` mientras estás logueado |

### Historial de contraseñas (para referencia)
| Fecha | Contraseña | Método de cambio |
|-------|-----------|-----------------|
| Abril 2026 | `Papucho123` → `PepAdmin2026` | updateUser() vía DevTools Console + recovery email |

---

## App Móvil — Identificadores

| Parámetro | Valor |
|-----------|-------|
| **App name** | PepEducation |
| **Slug** | PepEducation |
| **Bundle ID / Package** | `com.pepeducation.app` |
| **Deep link scheme** | `pepeducation://` |
| **EAS Project ID** | ⏳ Se genera al ejecutar `eas init` |

---

## Cuentas Pendientes de Crear

### EAS / expo.dev (GRATIS)
- **URL de registro:** https://expo.dev/signup
- **Recomendación:** Usar email `masm.a@outlook.com` para coherencia
- **Guardar:** email + contraseña

### Google Play Console ($25 único)
- **URL:** https://play.google.com/console
- **Pago:** $25 USD con tarjeta
- **Información necesaria:** Nombre completo o empresa, dirección, teléfono
- **Guardar:** Email Google utilizado + contraseña

### Apple Developer Program ($99/año)
- **URL:** https://developer.apple.com/programs/enroll/
- **Pago:** $99 USD/año con tarjeta o PayPal
- **Información necesaria:** Apple ID, nombre real, país
- **Guardar:** Apple ID + contraseña + datos de renovación anual
- **IDs importantes post-registro:**
  - **Team ID:** 10 caracteres (ej: `AB12CD34EF`) — ver en Membership
  - **App Store Connect App ID:** número largo (ej: `1234567890`) — ver en URL de App Store Connect

---

## Variables de Entorno — Referencia Completa

### Admin Web (`.env.local`)
```bash
NEXT_PUBLIC_SUPABASE_URL=https://mpdpbfaorquuqvhawwea.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<obtener de Supabase Settings → API>
```

### Mobile (`.env`)
```bash
EXPO_PUBLIC_SUPABASE_URL=https://mpdpbfaorquuqvhawwea.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=<obtener de Supabase Settings → API>
```

### Mobile — EAS Secrets (configurar en expo.dev si se necesitan en el build)
```bash
# Solo si se implementan notificaciones push:
FIREBASE_SERVER_KEY=<obtener de Firebase Console>
```

### Mobile — Google Play Submit
```
# google-play-key.json → en /mobile/ → NO en GitHub
# Archivo JSON de Service Account de Google Cloud
# Ver instrucciones en 04_mobile_android.md
```

---

## URLs Importantes de Referencia

| Servicio | URL |
|---------|-----|
| Admin web producción | https://pepeducation-admin.vercel.app |
| Supabase dashboard | https://supabase.com/dashboard/project/mpdpbfaorquuqvhawwea |
| Supabase Auth users | https://supabase.com/dashboard/project/mpdpbfaorquuqvhawwea/auth/users |
| Supabase SQL Editor | https://supabase.com/dashboard/project/mpdpbfaorquuqvhawwea/sql |
| Supabase Storage | https://supabase.com/dashboard/project/mpdpbfaorquuqvhawwea/storage/buckets |
| Supabase API Keys | https://supabase.com/dashboard/project/mpdpbfaorquuqvhawwea/settings/api |
| Vercel dashboard | https://vercel.com/dashboard |
| GitHub repo admin | https://github.com/msmgxe/pepeducation-admin |
| EAS builds | https://expo.dev (una vez creada la cuenta) |
| Google Play Console | https://play.google.com/console |
| App Store Connect | https://appstoreconnect.apple.com |
| Apple Developer | https://developer.apple.com/account |

---

## Política de Seguridad

1. **Nunca** subir `.env.local`, `.env`, `google-play-key.json` a GitHub (ya están en `.gitignore`)
2. **Nunca** exponer la `service_role` key de Supabase en el frontend
3. La `anon` key sí puede estar en el frontend (es pública por diseño)
4. Cambiar la contraseña del admin web periódicamente
5. Usar contraseñas distintas para cada servicio
6. Activar 2FA en GitHub, Supabase, Apple Developer y Google Play Console
# Pep Education — MCP Connectors y Herramientas IA

## ¿Qué es MCP?

**Model Context Protocol (MCP)** es un estándar abierto de Anthropic que permite a los modelos de lenguaje (como Claude) conectarse directamente con servicios externos (Supabase, Vercel, GitHub, etc.) sin necesidad de APIs manuales. Los conectores MCP exponen "herramientas" que Claude puede invocar durante una conversación.

---

## MCP Connectors Activos en el Proyecto

### 1. Supabase MCP
- **Propósito:** Ejecutar SQL, gestionar tablas, revisar logs directamente desde Claude Code
- **Proyecto conectado:** `mpdpbfaorquuqvhawwea` (proyecto de producción)
- **Herramientas disponibles:**
  | Herramienta | Descripción |
  |-------------|-------------|
  | `execute_sql` | Ejecutar queries SQL en el proyecto conectado |
  | `list_tables` | Listar tablas del proyecto |
  | `apply_migration` | Aplicar migraciones DDL |
  | `get_logs` | Ver logs del proyecto |
  | `list_projects` | Ver todos los proyectos Supabase de la cuenta |
  | `create_branch` | Crear branch de base de datos |
  | `generate_typescript_types` | Generar tipos TypeScript desde el schema |
  | `search_docs` | Buscar en documentación de Supabase |
  | `get_advisors` | Ver sugerencias de performance/seguridad |

- **Nota:** Para DDL/migraciones críticas, verificar en el SQL Editor del dashboard: https://supabase.com/dashboard/project/mpdpbfaorquuqvhawwea/sql

### 2. Vercel MCP
- **Propósito:** Gestionar deployments, ver logs, inspeccionar proyectos en Vercel
- **Herramientas disponibles:**
  | Herramienta | Descripción |
  |-------------|-------------|
  | `list_deployments` | Ver historial de deploys |
  | `get_deployment` | Estado de un deploy específico |
  | `get_deployment_build_logs` | Logs de build |
  | `get_runtime_logs` | Logs de runtime/ejecución |
  | `get_project` | Info del proyecto |
  | `list_projects` | Todos los proyectos |
  | `list_teams` | Teams de Vercel |
  | `deploy_to_vercel` | Hacer deploy |
  | `authenticate` | Autenticarse via OAuth |
  | `check_domain_availability_and_price` | Buscar dominio |
  | `search_vercel_documentation` | Buscar en docs de Vercel |

---

## Herramientas de IA Utilizadas en el Proyecto

### Claude Code (Anthropic)
- **Modelo base:** Claude Sonnet 4.6 (`claude-sonnet-4-6`)
- **Modelos disponibles:**
  | Modelo | ID | Uso recomendado |
  |--------|-----|----------------|
  | Opus 4.6 | `claude-opus-4-6` | Tareas complejas, arquitectura |
  | Sonnet 4.6 | `claude-sonnet-4-6` | Balance calidad/velocidad (default) |
  | Haiku 4.5 | `claude-haiku-4-5-20251001` | Tareas simples, respuestas rápidas |
- **Capacidades usadas:** Lectura de código, edición de archivos, ejecución de comandos bash, análisis de screenshots, MCP tools
- **Sesiones relevantes:** Desarrollo completo del admin web, configuración Supabase, setup Vercel, preparación mobile

### Claude Code — Sub-Agentes Especializados
- **Explore Agent:** Exploración profunda de codebase (audit del proyecto)
- **Plan Agent:** Diseño de planes de implementación
- **Vercel Deployment Expert:** Despliegues y CI/CD en Vercel
- **Vercel AI Architect:** Arquitectura de apps con IA

---

## MCP Connectors Recomendados para Agregar

### GitHub MCP (pendiente configurar)
- **Propósito:** Gestionar PRs, issues, branches, commits directamente desde Claude
- **Paquete:** `@modelcontextprotocol/server-github`
- **Configuración:**
  ```json
  {
    "name": "github",
    "command": "npx",
    "args": ["@modelcontextprotocol/server-github"],
    "env": {
      "GITHUB_PERSONAL_ACCESS_TOKEN": "<tu token de GitHub>"
    }
  }
  ```

### Filesystem MCP (disponible localmente)
- **Propósito:** Acceso seguro al sistema de archivos del proyecto
- **Herramientas:** read_file, write_file, list_directory, search_files

---

## Configuración de Claude Code

### Archivos de configuración relevantes
```
~/.claude/
├── settings.json          # Configuración global de Claude Code
├── settings.local.json    # Configuración local (no se comparte)
└── projects/
    └── -Users-marco-Proyectos-Pep/
        └── memory/        # Memoria persistente del proyecto
            ├── MEMORY.md              # Índice de memorias
            ├── project_overview.md    # Overview del proyecto
            ├── project_supabase.md    # Config Supabase
            ├── user_profile.md        # Perfil del usuario
            ├── feedback_rules.md      # Reglas de colaboración
            └── project_darkmode.md    # Pendiente dark mode
```

### Sistema de Memoria Persistente
Claude Code mantiene memoria entre sesiones del proyecto:
- **user:** Perfil de Marco (roles, preferencias, nivel técnico)
- **feedback:** Reglas aprendidas sobre cómo colaborar
- **project:** Estado actual del proyecto, decisiones tomadas
- **reference:** Dónde encontrar información en sistemas externos

---

## Flujo de Trabajo con IA (Recomendado)

### Para desarrollo de features nuevas:
```
1. Describir la feature a Claude Code en lenguaje natural
2. Claude revisa el código existente antes de proponer cambios
3. Claude implementa los cambios (Edit/Write tools)
4. Revisar los cambios antes de commitear
5. Claude puede hacer el commit y push si se autoriza
```

### Para debugging:
```
1. Compartir screenshot del error con Claude Code
2. Claude analiza la imagen + los logs del código
3. Claude propone y aplica el fix
4. Verificar que funciona
```

### Para deploys:
```
1. Claude verifica que el build local funciona (npm run build)
2. Claude hace git push → Vercel auto-deploys
3. Claude verifica el deploy via MCP Vercel
4. Si hay errores: Claude revisa build logs via MCP
```

---

## APIs y SDKs Utilizados

### Supabase JavaScript Client
- **Paquete:** `@supabase/supabase-js ^2.100.1`
- **Documentación:** https://supabase.com/docs/reference/javascript
- **Métodos principales usados:**
  ```typescript
  supabase.auth.signInWithPassword()
  supabase.auth.signUp()
  supabase.auth.verifyOtp()
  supabase.auth.signOut()
  supabase.auth.updateUser()
  supabase.auth.resetPasswordForEmail()
  supabase.auth.onAuthStateChange()
  supabase.from('tabla').select()
  supabase.from('tabla').insert()
  supabase.from('tabla').update()
  supabase.storage.from('bucket').upload()
  supabase.storage.from('bucket').getPublicUrl()
  ```

### Vercel API (via MCP)
- **SDK:** `@vercel/sdk` (disponible si se necesita programáticamente)
- **MCP Plugin:** `plugin:vercel-plugin:env`, `plugin:vercel-plugin:deployment-expert`

### EAS CLI
- **Paquete:** `eas-cli` (instalar globalmente: `npm i -g eas-cli`)
- **Comandos principales:**
  ```bash
  eas login                              # Autenticarse
  eas init                              # Inicializar proyecto
  eas build --platform android          # Build Android
  eas build --platform ios              # Build iOS
  eas build --platform all             # Ambas plataformas
  eas submit --platform android         # Submit a Play Store
  eas submit --platform ios             # Submit a App Store
  eas update                            # OTA update (sin rebuild)
  ```

### Expo SDK
- **Versión:** ~54.0.33
- **Documentación:** https://docs.expo.dev
- **Plugins utilizados:**
  - `expo-router`: Navegación file-based
  - `expo-image-picker`: Selección de fotos
  - `expo-splash-screen`: Pantalla de carga
  - `expo-haptics`: Feedback táctil
  - `expo-constants`: Constantes del dispositivo
  - `expo-font`: Carga de fuentes custom
  - `expo-linking`: Deep links

---

## Recursos de Documentación

| Recurso | URL |
|---------|-----|
| Supabase Docs | https://supabase.com/docs |
| Next.js Docs | https://nextjs.org/docs |
| Expo Docs | https://docs.expo.dev |
| EAS Build | https://docs.expo.dev/build/introduction |
| EAS Submit | https://docs.expo.dev/submit/introduction |
| Vercel Docs | https://vercel.com/docs |
| Tailwind CSS v4 | https://tailwindcss.com/docs |
| React Native | https://reactnative.dev/docs |
| Expo Router | https://docs.expo.dev/router/introduction |
| Apple Developer | https://developer.apple.com/documentation |
| Google Play Console Help | https://support.google.com/googleplay/android-developer |
| MCP Protocol | https://modelcontextprotocol.io |
| Claude Code Docs | https://docs.anthropic.com/claude-code |
# Pep Education — App Móvil (Detalle Técnico)

## Configuración del Proyecto

| Parámetro | Valor |
|-----------|-------|
| **Framework** | Expo 54 (React Native 0.81.5) |
| **Lenguaje** | TypeScript 5 |
| **Routing** | Expo Router v6 (file-based) |
| **Package name** | `com.pepeducation.app` |
| **App name** | PepEducation |
| **Slug** | PepEducation |
| **Deep link scheme** | `pepeducation://` |
| **Nueva arquitectura** | Habilitada (`newArchEnabled: true`) |
| **Orientación** | Portrait únicamente |
| **Interfaz** | Light + Dark mode automático (`userInterfaceStyle: "automatic"`) |

---

## Estructura de Archivos

```
mobile/
├── app/
│   ├── _layout.tsx              # Root: AuthProvider, fonts, routing lógico
│   ├── (auth)/
│   │   ├── _layout.tsx          # Stack navigator auth
│   │   ├── login.tsx            # Pantalla login (email + pass)
│   │   ├── register.tsx         # Registro (nombre, email, pass, confirmación)
│   │   ├── verify.tsx           # Verificación OTP (6 dígitos)
│   │   └── callback.tsx         # Handler OAuth redirect (magic links)
│   ├── (onboarding)/
│   │   ├── _layout.tsx          # Stack navigator onboarding
│   │   └── index.tsx            # Wizard 6 pasos (teléfono, peso, altura, edad, sexo, meds)
│   └── (tabs)/
│       ├── _layout.tsx          # Bottom tab navigator (5 tabs, support oculto)
│       ├── index.tsx            # Home: bienvenida, próxima cita, tips, notas
│       ├── weight.tsx           # Registro de peso + gráfico SVG + zoom
│       ├── progress.tsx         # LineChart progreso + achievement badges
│       ├── calendar.tsx         # Calendario mensual + crear/ver eventos
│       └── support.tsx          # Centro de soporte + contacto médico
├── context/
│   └── AuthContext.tsx          # Sesión, perfil, hasProfile, routing
├── lib/
│   └── supabase.ts              # Cliente Supabase con AsyncStorage
├── constants/
│   └── theme.ts                 # Colores light/dark + fonts por plataforma
├── hooks/
│   ├── use-color-scheme.ts      # Re-export de useColorScheme
│   └── use-color-scheme.web.ts  # Fix de hidratación para web
├── assets/
│   └── images/
│       ├── icon.png                       # Ícono de la app (1024×1024 recomendado)
│       ├── splash-icon.png                # Imagen splash screen
│       ├── favicon.png                    # Para versión web
│       ├── android-icon-foreground.png    # Ícono adaptativo Android (capa frontal)
│       ├── android-icon-background.png    # Ícono adaptativo Android (fondo)
│       └── android-icon-monochrome.png    # Ícono monocromático Android 13+
├── app.json                     # Configuración Expo
├── eas.json                     # Configuración EAS Build
├── .env                         # Variables de entorno (NO en GitHub)
├── .gitignore
├── expo-env.d.ts                # Tipos generados por Expo
├── tsconfig.json
└── package.json
```

---

## Flujo de Navegación

```
App Launch
    │
    ├── [Cargando fuentes + verificando sesión]
    │
    ├── Sin sesión → (auth)/login
    │                    ├── Login exitoso + tiene perfil → (tabs)/
    │                    ├── Login exitoso + sin perfil → (onboarding)/
    │                    └── Sin cuenta → register → verify → (onboarding)/
    │
    └── Con sesión
            ├── hasProfile = true → (tabs)/
            └── hasProfile = false → (onboarding)/

(onboarding)/ [6 pasos]
    1. Teléfono
    2. Peso actual + Peso meta
    3. Altura (cm o pies)
    4. Edad
    5. Sexo
    6. Medicamentos actuales
    → Guarda en profiles → redirige a (tabs)/

(tabs)/
    ├── index (Home) ←→ weight ←→ progress ←→ calendar
    └── support (href: null — accesible desde Home, no en nav)
```

---

## AuthContext — Manejo de Estado de Auth

```typescript
// mobile/context/AuthContext.tsx
interface AuthContextType {
  session: Session | null;         // Sesión de Supabase (JWT + refresh token)
  profile: Profile | null;         // Datos del perfil del usuario
  hasProfile: boolean;             // ¿Completó el onboarding?
  loading: boolean;                // Cargando sesión inicial
  refreshProfile: () => Promise<void>;  // Actualizar datos del perfil
}

// Importante: refreshProfile() debe llamarse SOLO al final del flujo de onboarding,
// NO durante la grabación de datos intermedios.
// Si se llama antes, TOKEN_REFRESHED dispara hasProfile=true prematuramente
// y el layout redirige antes de que el usuario vea la pantalla final de onboarding.
```

---

## Cliente Supabase Mobile

```typescript
// mobile/lib/supabase.ts
import { createClient } from '@supabase/supabase-js';
import AsyncStorage from '@react-native-async-storage/async-storage';

export const supabase = createClient(
  process.env.EXPO_PUBLIC_SUPABASE_URL!,
  process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!,
  {
    auth: {
      storage: AsyncStorage,           // Persistencia de sesión nativa
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,       // NO usar flowType: 'pkce' — rompe React Native
    },
  }
);
```

> ⚠️ **Importante:** NO agregar `flowType: 'pkce'` al cliente de mobile. El PKCE flow está pensado para web y causa problemas en React Native con el manejo de URLs.

---

## Sistema de Temas (Light/Dark Mode)

```typescript
// mobile/constants/theme.ts
export const Colors = {
  light: {
    primary: '#7B2D8B',
    primaryMid: '#C4A2DC',
    primaryPale: '#F4EDF8',
    accent: '#FFD700',
    background: '#FFFFFF',
    surface: '#F9FAFB',
    text: '#1A1A1A',
    textSecondary: '#6B7280',
    border: '#E5E7EB',
  },
  dark: {
    primary: '#A855CC',
    primaryMid: '#7B2D8B',
    primaryPale: '#2D1B35',
    accent: '#FFD700',
    background: '#0F0F0F',
    surface: '#1A1A1A',
    text: '#F9FAFB',
    textSecondary: '#9CA3AF',
    border: '#374151',
  },
};

// Uso en screens:
// const colorScheme = useColorScheme();
// const colors = Colors[colorScheme ?? 'light'];
```

---

## Variables de Entorno Mobile

Archivo `.env` (en `mobile/` — NO commitear a GitHub):

```bash
EXPO_PUBLIC_SUPABASE_URL=https://mpdpbfaorquuqvhawwea.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=<anon key del proyecto>
```

> El prefijo `EXPO_PUBLIC_` es requerido para que las variables sean accesibles en el bundle de la app. Variables sin este prefijo son solo para el proceso de build (no disponibles en runtime de la app).

---

## Dependencias Completas

```json
{
  "dependencies": {
    "@expo/vector-icons": "^15.0.3",
    "@react-native-async-storage/async-storage": "2.2.0",
    "@react-navigation/bottom-tabs": "^7.4.0",
    "@react-navigation/elements": "^2.6.3",
    "@react-navigation/native": "^7.1.8",
    "@supabase/supabase-js": "^2.100.1",
    "expo": "~54.0.33",
    "expo-constants": "~18.0.13",
    "expo-font": "~14.0.11",
    "expo-haptics": "~15.0.8",
    "expo-image": "~3.0.11",
    "expo-image-picker": "~17.0.10",
    "expo-linking": "~8.0.11",
    "expo-router": "~6.0.23",
    "expo-splash-screen": "~31.0.13",
    "expo-status-bar": "~3.0.9",
    "expo-symbols": "~1.0.8",
    "expo-system-ui": "~6.0.9",
    "expo-web-browser": "~15.0.10",
    "react": "19.1.0",
    "react-dom": "19.1.0",
    "react-native": "0.81.5",
    "react-native-chart-kit": "^6.12.0",
    "react-native-gesture-handler": "~2.28.0",
    "react-native-reanimated": "~4.1.1",
    "react-native-safe-area-context": "~5.6.0",
    "react-native-screens": "~4.16.0",
    "react-native-svg": "15.12.1",
    "react-native-url-polyfill": "^3.0.0",
    "react-native-web": "~0.21.0",
    "react-native-worklets": "0.5.1"
  }
}
```

---

## Comandos de Desarrollo

```bash
cd /Users/marco/Proyectos/Pep/mobile

# Instalar dependencias
npm install

# Servidor de desarrollo (con Expo Go o dev client)
npx expo start

# Correr en simulador iOS (requiere Xcode en Mac)
npx expo run:ios

# Correr en emulador Android (requiere Android Studio)
npx expo run:android

# Build de desarrollo (para testear en dispositivo real)
npx eas build --platform ios --profile development
npx eas build --platform android --profile development

# Build de producción
npx eas build --platform ios --profile production
npx eas build --platform android --profile production

# Actualización OTA (sin rebuild completo — cambios de JS/assets)
npx eas update --branch production --message "Fix: descripción del cambio"
```

---

## Features Implementadas

| Feature | Pantalla | Estado |
|---------|----------|--------|
| Login email/password | (auth)/login | ✅ |
| Registro de usuario | (auth)/register | ✅ |
| Verificación OTP | (auth)/verify | ✅ |
| Onboarding 6 pasos | (onboarding)/index | ✅ |
| Dashboard Home | (tabs)/index | ✅ |
| Registro de peso | (tabs)/weight | ✅ |
| Gráfico de progreso | (tabs)/weight | ✅ (SVG + pinch-zoom) |
| Filtros temporales gráfico | (tabs)/weight | ✅ (1M, 3M, 6M, Todo) |
| Subida de foto de peso | (tabs)/weight | ✅ (image picker) |
| Achievements/badges | (tabs)/progress | ✅ |
| LineChart progreso | (tabs)/progress | ✅ (react-native-chart-kit) |
| Calendario de citas | (tabs)/calendar | ✅ |
| Crear eventos | (tabs)/calendar | ✅ |
| Contacto médico (WhatsApp) | (tabs)/support | ✅ |
| FAQ | (tabs)/support | ⏳ Placeholder |
| Dark mode | Todas | ✅ |
| Push notifications | - | ❌ No implementado |
| Biometría/Face ID | - | ❌ No implementado |

---

## Problemas Conocidos y Soluciones

| Problema | Causa | Solución |
|---------|-------|----------|
| `flowType: 'pkce'` causa crashes | PKCE no es compatible con React Native URL handling | Eliminar `flowType: 'pkce'` del cliente Supabase mobile |
| `refreshProfile()` llamado temprano causa redirect prematuro | `TOKEN_REFRESHED` event dispara `hasProfile=true` | Llamar `refreshProfile()` SOLO al final del onboarding, en el tap final del usuario |
| Iconos aparecen como `[?]` en simulador | MaterialCommunityIcons con texto emoji | Usar solo componentes de icono de `@expo/vector-icons`, no caracteres emoji |
| App no encuentra variables de entorno | Falta prefijo `EXPO_PUBLIC_` | Todas las vars de entorno accesibles en runtime deben tener `EXPO_PUBLIC_` |
