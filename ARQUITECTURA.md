# Arquitectura de Pep Education

Este documento detalla la estructura lógica y de infraestructura del proyecto, permitiendo una visión integral para soporte y mantenimiento a largo plazo.

## Diagrama de Arquitectura Global

```mermaid
graph TD;
    %% Definiendo componentes de Usuario Final
    subgraph Clients ["Interfaces de Usuario"]
        A_Web[("🌍 Admin Web\n(Next.js 16)")];
        A_Mobile[("📱 App Móvil\n(React Native / Expo)")];
    end

    %% Definiendo el API / Backend Services
    subgraph BaaS ["Backend como Servicio (Supabase)"]
        S_Auth{"🔐 Auth\n(OTP Email/Password)"};
        S_DB[("🗄️ PostgreSQL\n(Datos & RLS)")];
        S_Storage{"📂 Storage\n(Fotos/Archivos)"};
    end

    %% Despliegues y DevOps
    subgraph DevOps ["Despliegue y Distribución"]
        D_Vercel(("🚀 Vercel\n(Hosting Web Admin)"));
        D_EAS(("📦 EAS Build\n(iOS / Android)"));
        D_AppStore>["🍎 App Store / TestFlight"];
        D_PlayStore>["👾 Google Play Store"];
    end

    %% Relaciones / Conexiones
    A_Web -- "Llamadas API REST / Supabase Client" --> S_Auth
    A_Web -- "CRUD protegido por RLS" --> S_DB
    A_Mobile -- "Llamadas API REST / Supabase Client" --> S_Auth
    A_Mobile -- "CRUD protegido por RLS" --> S_DB
    A_Mobile -- "Sube fotos (Mediciones)" --> S_Storage

    %% DevOps Conexiones
    A_Web -. "CI/CD o Deploy Manual" .-> D_Vercel
    A_Mobile -. "eas build" .-> D_EAS
    D_EAS -. "eas submit" .-> D_AppStore
    D_EAS -. "eas submit" .-> D_PlayStore

    classDef web fill:#136cba,stroke:#fff,color:#fff;
    classDef mobile fill:#7B2D8B,stroke:#fff,color:#fff;
    classDef supabase fill:#3ecf8e,stroke:#fff,color:#000;
    classDef cloud fill:#20232a,stroke:#fff,color:#fff;

    class A_Web web;
    class A_Mobile mobile;
    class S_Auth,S_DB,S_Storage supabase;
    class D_Vercel,D_EAS,D_AppStore,D_PlayStore cloud;
```

## Resumen Lógico de Componentes

### 1. Frontend Web (Vercel)
- **Tecnología**: Next.js 16 (App Router) + Tailwind CSS 4.
- **URL**: `https://pepeducation-admin.vercel.app`
- **Objetivo**: Panel administrativo usado para gestionar pacientes (`role = 'admin'`).
- **Conectividad**: SDK nativo `@supabase/supabase-js`.

### 2. Frontend Móvil (iOS / Android)
- **Tecnología**: Expo SDK 54 / React Native / Expo Router.
- **Objetivo**: App usada por los pacientes finales (`role = 'usuario'`).
- **Conectividad**: SDK interactuando por medio de sesiones persistidas localmente en `AsyncStorage`.

### 3. Backend (Supabase)
- **Base de Datos**: PostgreSQL alojado (`mpdpbfaorquuqvhawwea`). Tablas clave: `profiles`, `measurements`, `patient_medications`, `calendar_events`, `dosages`.
- **Autenticación**: Email + Password / OTP.
- **Políticas (RLS)**: Seguridad a nivel de base de datos usando `auth.uid()`.

## Flujo Crítico (Trazabilidad)
1. **Registro**: Usuario se registra en App o Admin.
2. **Auth**: Supabase gestiona sesión y JWT.
3. **Perfil**: Trigger o App inserta en `public.profiles`.
4. **Admin**: Visualización centralizada filtrando por roles.

