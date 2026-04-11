# Guía de Despliegue — Pep Education

> Última actualización: 2026-04-06
> Proyecto: Admin Web (Next.js 16) + App Móvil iOS/Android (Expo)
> Backend: Supabase (`mpdpbfaorquuqvhawwea.supabase.co`)

---

## Índice

1. [App iOS — Compartir con familiares/testers](#1-app-ios--compartir-con-familiartesters)
2. [App Android — Generar APK](#2-app-android--generar-apk)
3. [Admin Web — Publicar en Vercel](#3-admin-web--publicar-en-vercel)
4. [Resumen de variables de entorno](#4-resumen-de-variables-de-entorno)

---

## 1. App iOS — Compartir con familiar/testers

### Requisitos previos

| Requisito | Detalle |
|-----------|---------|
| Apple Developer Account | $99 USD/año en [developer.apple.com](https://developer.apple.com) |
| EAS CLI instalado | `npm install -g eas-cli` |
| Cuenta Expo | Gratis en [expo.dev](https://expo.dev) |

### Opción A — TestFlight (recomendado para familia)

TestFlight permite invitar hasta **10,000 testers** por email. El familiar instala la app desde TestFlight sin pasar por la App Store.

**Paso 1 — Configurar EAS (una sola vez)**
```bash
cd /Users/marco/Proyectos/Pep/mobile
eas login                  # inicia sesión en expo.dev
eas build:configure        # vincula el proyecto al account
```

**Paso 2 — Agregar perfil iOS en `eas.json`**

El perfil `preview` con `distribution: internal` requiere registrar el UDID del dispositivo.
Para TestFlight usa el perfil de `production` o crea uno específico:

```json
"preview-ios": {
  "distribution": "store",
  "ios": { "simulator": false },
  "env": {
    "EXPO_PUBLIC_SUPABASE_URL": "https://mpdpbfaorquuqvhawwea.supabase.co",
    "EXPO_PUBLIC_SUPABASE_ANON_KEY": "tu_anon_key"
  }
}
```

**Paso 3 — Compilar para iOS**
```bash
eas build --platform ios --profile production
# El build corre en la nube (~15-20 min)
# Al terminar te da un enlace al .ipa
```

**Paso 4 — Subir a TestFlight**
```bash
eas submit --platform ios
# EAS sube automáticamente el build a App Store Connect
# O descarga el .ipa y súbelo manualmente con Transporter (Mac App Store)
```

**Paso 5 — Invitar al familiar**
1. Entra a [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Selecciona tu app → **TestFlight**
3. Clic en **"+" → Add External Testers**
4. Ingresa el email del familiar
5. El familiar recibe un email, instala **TestFlight** (gratis en App Store) y acepta la invitación
6. La app aparece en su TestFlight lista para instalar

> **Actualizar la app**: cada `eas build + eas submit` nuevo aparece automáticamente en TestFlight del familiar.

---

### Opción B — Expo Go (solo para pruebas de desarrollo, sin compilar)

Solo funciona si el familiar tiene Expo Go instalado y está en la misma red WiFi, o con una cuenta Expo.

```bash
cd /Users/marco/Proyectos/Pep/mobile
npx expo start
# Comparte el QR con el familiar
# El familiar abre Expo Go y escanea el QR
```

> **Limitación**: No funciona en producción real. Solo para mostrar prototipos rápidos.

---

### Opción C — Ad Hoc (sin App Store, hasta 100 dispositivos)

Requiere registrar el **UDID** del iPhone del familiar en tu Apple Developer account.

**Paso 1 — Obtener el UDID del iPhone del familiar**
- En el iPhone: Ajustes → General → Información → deslizar hasta ver el UDID
- O conectar a Mac con Finder → seleccionar el dispositivo → clic en el número de serie hasta que cambie a UDID

**Paso 2 — Registrar el dispositivo**
```bash
eas device:create
# Te preguntará por el UDID y un nombre para el dispositivo
```

**Paso 3 — Build Ad Hoc**
```bash
eas build --platform ios --profile preview
# El perfil "preview" usa distribution:internal = Ad Hoc automáticamente
```

**Paso 4 — Instalar en el iPhone**
- EAS genera un link de instalación QR
- El familiar abre el link en Safari de su iPhone → instala directo

---

## 2. App Android — Generar APK

### Requisitos previos

```bash
npm install -g eas-cli
eas login
```

### Generar APK para instalar directamente (sin Play Store)

```bash
cd /Users/marco/Proyectos/Pep/mobile
eas build --platform android --profile preview
```

- Build en la nube: ~10-15 minutos
- Al terminar: EAS muestra un **link de descarga del APK**
- El familiar descarga el `.apk` en su Android
- Ajustes → Seguridad → **Permitir fuentes desconocidas** (o "Instalar apps desconocidas")
- Abrir el `.apk` descargado → instalar

> El APK contiene las variables de Supabase embebidas del perfil `preview` en `eas.json`.

---

### Subir a Google Play Store (distribución masiva)

**Requisito**: Cuenta Google Play Developer ($25 USD pago único en [play.google.com/console](https://play.google.com/console))

**Paso 1 — Build AAB (Android App Bundle)**
```bash
eas build --platform android --profile production
# Genera un .aab optimizado para Play Store
# autoIncrement: true incrementa la versión automáticamente
```

**Paso 2 — Subir a Play Console**
```bash
eas submit --platform android
# EAS sube automáticamente a la pista Interna/Alpha/Beta/Producción
```

O manualmente:
1. Entra a [play.google.com/console](https://play.google.com/console)
2. Crea la app → **Versiones → Testing interno → Crear versión**
3. Sube el `.aab`
4. Agrega email del familiar en **"Probadores"**
5. El familiar recibe enlace de instalación

---

## 3. Admin Web — Publicar en Netlify

### Opción A — Subir carpeta (sin Git, más rápido)

**Paso 1 — Construir el proyecto**
```bash
cd /Users/marco/Proyectos/Pep/admin
npm run build
# Genera la carpeta `out/` con el sitio estático completo
# Las variables NEXT_PUBLIC_* quedan embebidas en el bundle
```

**Paso 2 — Subir a Netlify**
1. Ve a [app.netlify.com](https://app.netlify.com) → inicia sesión (gratis)
2. En la pantalla principal: **"Deploy manually"** o arrastra la carpeta
3. Arrastra `admin/out/` al área de drop en Netlify
4. En ~30 segundos tu sitio queda en: `https://nombre-aleatorio.netlify.app`

> **Para actualizar**: repite `npm run build` y arrastra la nueva carpeta `out/`.

---

### Opción B — Con GitHub (auto-deploy al hacer push)

**Paso 1 — Crear repositorio**
```bash
cd /Users/marco/Proyectos/Pep/admin
git init
git add .
git commit -m "Initial deploy"
```

Crea un repo nuevo en [github.com](https://github.com/new), luego:
```bash
git remote add origin https://github.com/TU_USUARIO/pep-admin.git
git push -u origin main
```

**Paso 2 — Conectar Netlify**
1. [app.netlify.com](https://app.netlify.com) → **Add new site → Import an existing project**
2. Selecciona **GitHub** → autoriza acceso → elige el repo `pep-admin`
3. Netlify detecta el `netlify.toml` automáticamente:
   - Build command: `npm run build`
   - Publish directory: `out`
4. Clic en **Deploy site**

**Desde este momento**: cada `git push` a `main` redeploya automáticamente.

---

## 4. Dominio personalizado en Netlify

### Dominio gratuito incluido

Al deployar en Netlify obtienes gratis: `tu-nombre.netlify.app`

Para cambiar el subdominio:
- Netlify → Site → **Domain management → Options → Edit site name**
- Cambia a algo como: `pep-admin.netlify.app`

---

### Dominio personalizado (pagas solo el dominio, ~$10-15 USD/año)

#### Registrar un dominio

Opciones recomendadas (precio por año):
| Registrador | URL | Precio aprox |
|------------|-----|-------------|
| Namecheap | [namecheap.com](https://namecheap.com) | $8-12/año |
| Porkbun | [porkbun.com](https://porkbun.com) | $8-10/año |
| Google Domains / Squarespace | [domains.squarespace.com](https://domains.squarespace.com) | $12-15/año |
| GoDaddy | [godaddy.com](https://godaddy.com) | $10-20/año |

**Ejemplo**: compras `pepeducation.com` o `admin.pepeducation.com`

#### Conectar el dominio a Netlify

**Paso 1 — Agregar dominio en Netlify**
1. Netlify → tu sitio → **Domain management → Add custom domain**
2. Escribe tu dominio: `pepeducation.com`
3. Netlify mostrará los DNS que debes configurar

**Paso 2 — Configurar DNS en tu registrador**

Netlify te dará estos valores (ejemplo):
```
Tipo    Nombre    Valor
A       @         75.2.60.5
CNAME   www       apex-loadbalancer.netlify.com
```

En tu registrador (ej. Namecheap):
- Panel → **Advanced DNS** → Add Record
- Agrega los registros A y CNAME exactos que Netlify indica

**Paso 3 — Esperar propagación**
- DNS tarda 5 minutos a 48 horas en propagarse
- Netlify activa **HTTPS automático** (certificado SSL gratuito via Let's Encrypt)
- Tu sitio queda en `https://pepeducation.com` con candado verde

---

### Con subdominio (ej. `admin.tudominio.com`)

Si ya tienes un dominio y quieres usar `admin.tudominio.com`:

En tu registrador agrega:
```
Tipo     Nombre    Valor
CNAME    admin     tu-nombre.netlify.app
```

En Netlify → Domain management → agrega `admin.tudominio.com`

---

## 5. Resumen de variables de entorno

### Admin Web (`admin/.env.local`)
```env
NEXT_PUBLIC_SUPABASE_URL=https://mpdpbfaorquuqvhawwea.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...
```
> Con `output: 'export'` estas variables se embeben en el build. No necesitas configurarlas en Netlify si compilas localmente.

### App Móvil (`mobile/.env`)
```env
EXPO_PUBLIC_SUPABASE_URL=https://mpdpbfaorquuqvhawwea.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...
```
> Para builds EAS (nube), las variables van en `eas.json` → perfil correspondiente, ya que EAS no lee `.env` local.

### EAS Build (`mobile/eas.json`)
- **preview** (APK/TestFlight): variables Supabase correctas ✅
- **production** (Play Store/App Store): variables Supabase correctas ✅
- ~~production antiguo~~: apuntaba a proyecto Supabase diferente — corregido ✅

---

## Flujo completo resumido

```
Desarrollo local
      │
      ├── Admin Web
      │     ├── npm run build  →  carpeta out/
      │     └── Subir out/ a Netlify  →  https://pep-admin.netlify.app
      │
      └── App Móvil
            ├── Android APK
            │     └── eas build --platform android --profile preview
            │           →  Descarga .apk  →  Instalar en Android
            │
            └── iOS TestFlight
                  └── eas build --platform ios --profile production
                        →  eas submit --platform ios
                              →  App Store Connect → TestFlight
                                    →  Invitar familiar por email
```
