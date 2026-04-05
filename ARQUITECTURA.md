# Arquitectura de Pep Education

Este documento detalla la estructura lógica y de infraestructura del proyecto, permitiendo una visión integral para soporte y mantenimiento a largo plazo.

## Diagrama de Arquitectura Global

```mermaid
graph TD;
    %% Definiendo componentes de Usuario Final
    subgraph Clients ["Interfaces de Usuario"]
        A_Web[("🌍 Admin Web\n(Next.js 14)")];
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
        D_Netlify(("🚀 Netlify\n(Hosting Web)"));
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
    A_Web -. "CI/CD o Deploy Manual" .-> D_Netlify
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
    class D_Netlify,D_EAS,D_AppStore,D_PlayStore cloud;
```

## Resumen Lógico de Componentes

### 1. Frontend Web (Netlify)
- **Tecnología**: Next.js 14 (App Router) + Tailwind CSS.
- **Objetivo**: Panel administrativo usado por los médicos o personal de Pep Education para gestionar pacientes (`role = 'patient' | 'usuario'`).
- **Conectividad**: SDK nativo `@supabase/supabase-js`.

### 2. Frontend Móvil (iOS / Android)
- **Tecnología**: Expo SDK 54 / React Native / Expo Router.
- **Objetivo**: App usada por los pacientes finales.
- **Conectividad**: SDK interactuando por medio de sesiones persistidas localmente en `AsyncStorage`. Sin soporte PKCE por la ausencia de WebCrypto nativo en JS.

### 3. Backend (Supabase)
- **Base de Datos**: PostgreSQL alojado. Tablas clave: `profiles`, `measurements`, `patient_medications`, `calendar_events`.
- **Autenticación**: Email + OTP numérico (6 dígitos) vía plantillas personalizadas.
- **Políticas (Row Level Security - RLS)**: La seguridad principal no requiere un "backend intermedio" (Node/Python); se valida directamente a nivel de base de datos usando `auth.uid()`.

## Flujo Crítico (Trazabilidad)
1. **El usuario se registra en la App**: Se crea cuenta en Auth de Supabase.
2. **Se envía OTP**: Supabase gestiona el envío. El usuario ingresa el código.
3. **Se crea Perfil (Trigger o App)**: Se inserta registro en la tabla `profiles`.
4. **Administrador lo visualiza**: El Admin web hace un query de todos los usuarios donde `role` incluya `'usuario'` o `'patient'`.
