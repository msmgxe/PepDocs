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
