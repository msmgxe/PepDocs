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
