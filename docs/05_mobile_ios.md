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
