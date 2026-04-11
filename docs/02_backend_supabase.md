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
