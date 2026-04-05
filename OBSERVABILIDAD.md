# Observabilidad y Trazabilidad — Pep Education

La observabilidad es clave para asegurar la estabilidad, reducir el tiempo en la resolución de problemas (soporte) y entender el comportamiento de los usuarios tanto en la Admin Web como en las aplicaciones móviles.

## 1. Logs y Monitoreo de Errores

### Frontend Web & Móvil (Recomendado: Sentry)
* **Sentry** es el estándar de la industria, muy recomendado por su buena integración con Next.js y React Native (Expo).
* **Beneficios:** 
   - Reporte de *Crashes* con `stack traces` de Javascript ya source-mapeados.
   - Rendimiento (APM), identificando cuellos de botella en la renderización de pantallas en la app móvil.
* **Integración en Expo:** `@sentry/react-native`. Permite atrapar cualquier rechazo de la aplicación sin control, fallas de API e interacciones caídas.

### Backend & API (Supabase Logs)
Supabase ya ofrece Logs nativos de Postgres, API (PostgREST) y Auth:
1. Ir al panel de control de Supabase → **Logs / Explorer**.
2. Crear un filtro avanzado en **Auth Logs** para monitorizar las validaciones OTP.
   ```sql
   select
     timestamp,
     event_message,
     user_id
   from
     auth.audit_log_entries
   ```
3. Se recomienda conectar Supabase con un proveedor como **Logflare** o **Datadog** mediante el servicio de webhooks si el tráfico empieza a escalar fuerte.

## 2. Métricas y Trazabilidad Funcional

### Trazabilidad Funcional entre Componentes
Para lograr un buen seguimiento funcional, se debe inyectar y pasar un `correlation_id` a través de los componentes principales.
* Al usar una llamada a la API con el SDK de Supabase o requests generales, el servidor y el cliente deben usar el ID del usuario (`user_id`).
* Grabar trazas de métricas personalizadas (Ej.: **"Onboarding Finalizado"** o **"Registro de Peso"**) con etiquetas, para aislar usuarios con problemas de registro. Recomiendo **PostHog** nativo con Expo/React. Nos dará analytics completos y nos dirá dónde se estancan los usuarios.

## 3. Guía de Implementación Básica (Sentry/PostHog)

1. En el Admin (`/admin`), agregar el handler de Sentry en el App Router (`app/error.tsx` y `app/global-error.tsx`).
2. En la App Móvil (`/mobile`), envolver el `_layout.tsx` (RootLayout) con un Sentry Wrapper:
   ```typescript
   import * as Sentry from '@sentry/react-native';

   Sentry.init({
     dsn: 'TU_DSN_AQUI',
     debug: true // En development
   });

   export default Sentry.wrap(RootLayout);
   ```
3. Para Custom Metrics / Analytics, invoca a la capa de tracking en los callbacks correctos:
   ```typescript
   PostHog.capture('registro_peso', {
     peso: current_weight_kg,
     usuario: session.user.id
   })
   ```
