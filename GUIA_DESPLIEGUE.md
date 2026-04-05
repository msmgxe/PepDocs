# Guía Consolidada de Despliegue — Pep Education

Esta guía simplifica el proceso de lanzamiento para las tres plataformas requeridas: **Web (Admin)**, **Móvil iOS**, y **Móvil Android**.

En la arquitectura depurada, contamos con dos únicas fuentes de código:
1. `admin/`: Para la plataforma web (Next.js)
2. `mobile/`: Para iOS y Android que comparten la misma base (Expo React Native)

---

## 1. Web: Next.js Panel de Administración

### Requisitos previos:
* Node.js v18+.
* Cuenta configurada en Netlify.

### Pasos de Despliegue:
1. **Compilación Local:**
   ```bash
   cd /Users/marco/Proyectos/Pep/admin
   npm run build
   ```
   *Esto generará la carpeta `out/` con el sitio estático optimizado.*

2. **Publicar en Netlify:**
   Toma la carpeta `out/` y pégala manualmente (drag and drop) en [app.netlify.com](https://app.netlify.com/drop).
   O de forma automática mediante la integración de un repositorio Github con Netlify.

---

## 2. Móvil: Android SDK (Google Play & APK)

### Requisitos previos:
* `eas-cli` instalado (`npm install -g eas-cli`).
* Cuenta en Google Play Store (para producción).
* Fichero configurado en `/mobile/eas.json`.

### Pasos de Despliegue:
1. **Generar el archivo base (APK) para pruebas o instalacion manual:**
   ```bash
   cd /Users/marco/Proyectos/Pep/mobile
   eas build --platform android --profile preview
   ```
   *EAS procesará la construcción y entregará un link para descargar el `.apk`. Ideal para QA intern.*

2. **Generar para Google Play Store (AAB):**
   ```bash
   eas build --platform android --profile production
   eas submit --platform android
   ```
   *El formato `.aab` (Android App Bundle) es el estándar actual para subir aplicaciones a la consola de Play Store.*

---

## 3. Móvil: iOS SDK (App Store & TestFlight)

### Requisitos previos:
* Suscripción activa al Apple Developer Program ($99 USD).
* Configuración en `eas.json` lista.

### Pasos de Despliegue:
1. **Compilar versión para producción (Lista para App Store):**
   ```bash
   cd /Users/marco/Proyectos/Pep/mobile
   eas build --platform ios --profile production
   ```
   *Este proceso dura alrededor de 15 a 20 minutos. EAS Cloud maneja certificados.*

2. **Enviar a TestFlight / App Store:**
   ```bash
   eas submit --platform ios
   ```
   *Una vez el comando finalice, la aplicación estará procesando en TestFlight (vía App Store Connect) en donde podras distribuirla internamente, o pasar a revisión oficial por Apple.*

> **Nota importante de unificación:** Gracias a Expo / EAS, los perfiles y certificados se centralizan en la nube. Las variables de configuración de Supabase, los Keys de Apple, y la Secret account Key (.json) de Google deben de colocarse en el Dashboard de Expo y no hardcoded en los proyectos de producción.
