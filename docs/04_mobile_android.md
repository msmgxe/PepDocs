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
