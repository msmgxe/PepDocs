# Pep Education — App Flutter (iOS + Android)

## Descripción General

Versión Flutter de la app móvil de Pep Education. Reescritura completa desde React Native/Expo a Flutter/Dart para eliminar dependencias de Metro bundler y obtener compilación nativa directa.

| Parámetro | Valor |
|-----------|-------|
| Framework | Flutter 3.41.6 |
| Lenguaje | Dart 3.x (null safety) |
| Ubicación | `/Users/marco/Proyectos/Pep/mobile_flutter/` |
| Bundle ID iOS | `com.pepeducation.pepEducation` |
| Package Android | `com.pepeducation.pep_education` |
| Supabase | `mpdpbfaorquuqvhawwea` (producción) |

---

## Estructura del Proyecto

```
mobile_flutter/
├── lib/
│   ├── main.dart                        # Entry point, Supabase init, AuthGate
│   ├── constants/
│   │   └── theme.dart                   # Colores y tema Material 3
│   ├── services/
│   │   └── supabase_service.dart        # Todas las llamadas a Supabase
│   ├── widgets/
│   │   ├── main_shell.dart              # Bottom nav + onboarding check
│   │   └── pep_logo.dart               # Widget logo Pep Education (corazón + texto)
│   └── screens/
│       ├── auth/
│       │   ├── login_screen.dart        # Login email/password + logo
│       │   └── register_screen.dart     # Registro nuevo usuario + logo
│       ├── onboarding/
│       │   └── onboarding_screen.dart   # Nombre, sexo, fecha nacimiento, altura, peso
│       └── tabs/
│           ├── home_screen.dart         # Bienvenida, cards datos personales, BMI, próxima cita
│           ├── weight_screen.dart       # CRUD pesajes + fotos + IMC + toggle kg/lbs
│           ├── progress_screen.dart     # Gráfica fl_chart + filtros período + figura humana
│           ├── reminders_screen.dart    # Calendario + CRUD citas nativas
│           └── support_screen.dart      # Botón WhatsApp
├── ios/                                 # Proyecto Xcode (abre .xcworkspace)
├── android/                             # Proyecto Android Gradle
└── pubspec.yaml                         # Dependencias
```

---

## Dependencias Principales

```yaml
supabase_flutter: ^2.9.0      # Auth + DB + Storage
fl_chart: ^0.69.0             # Gráfica de peso
image_picker: ^1.1.2          # Cámara y galería
table_calendar: ^3.2.0        # Widget calendario
device_calendar: ^4.4.0       # Sincronizar con calendario nativo
intl: ^0.20.2                 # Fechas en español
shared_preferences: ^2.5.3    # Persistencia local
url_launcher: ^6.4.1          # Abrir WhatsApp
```

---

## Base de Datos — Columnas Requeridas

### Tabla `profiles`
| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | uuid | PK |
| `auth_uid` | uuid | FK → auth.users |
| `full_name` | text | Nombre completo |
| `role` | text | `'patient'` |
| `height_cm` | numeric | Estatura en cm |
| `weight_kg` | numeric | Peso inicial |
| `target_weight_kg` | numeric | Meta de peso |
| `sex` | text | `'male'` o `'female'` — **migración 11** |
| `birth_date` | date | Fecha de nacimiento — **migración 11** |

> Ejecutar `supabase_backup/11_add_sex_birthdate.sql` en producción si no está aplicado.

### Tabla `measurements`
`id`, `patient_id`, `weight_kg`, `measurement_date` (timestamptz), `notes`, `photo_url`

### Tabla `calendar_events`
`id`, `patient_id`, `title`, `event_date` (timestamptz), `notes`

---

## Pantallas de la App

### 1. Login
- Logo Pep Education (widget `PepLogo`: corazón blanco sobre círculo morado)
- Email y contraseña
- Botón "Iniciar sesión"
- Link a Registro

### 2. Registro
- Logo Pep Education reducido
- Nombre completo, email, contraseña (con confirmación)
- Redirige a Onboarding al crear cuenta

### 3. Onboarding
- Logo Pep Education
- Campos: nombre completo, sexo (chips Masculino/Femenino), fecha de nacimiento (opcional), estatura (cm), peso actual (kg), peso meta (kg)
- Solo se muestra la primera vez (flag `onboarding_done` en SharedPreferences)
- Guarda en tabla `profiles`

### 4. Inicio (Home)
- Saludo personalizado (Buenos días/tardes/noches + nombre)
- **Fila de datos personales**: estatura, sexo, edad (calculada desde `birth_date`)
- Tarjeta IMC con índice calculado y categoría (color según rango)
- Cards peso actual y peso objetivo
- Próxima cita programada

### 5. Peso
- Toggle **kg ↔ lbs** en AppBar (conversión automática, siempre guarda en kg)
- Lista de pesajes: cada registro muestra peso en unidad elegida + **badge IMC** con categoría
- FAB `+` para agregar; toque en registro para editar
- Modal de registro: fecha, peso, notas, **Cámara** y **Galería** como botones separados
- Fotos subidas a Supabase Storage bucket `patient-photos`

### 6. Progreso
- **Tarjeta figura humana**: silueta según sexo + datos (peso, estatura, IMC, total bajado/subido)
- Cards resumen: peso actual, meta, diferencia
- **Filtros de período**: `SegmentedButton` con 1M · 3M · 6M · Todo
- Gráfica de línea (`fl_chart`) filtrada por período con tooltip interactivo
- Línea punteada verde = meta de peso
- Historial de los últimos 10 registros del período seleccionado

### 7. Recordatorios
- Calendario mensual (`table_calendar`) con puntos en días con citas
- CRUD completo de citas
- Sincronización con calendario nativo del dispositivo (iOS/Android)

### 8. Soporte
- Botón de contacto por WhatsApp

---

## Cómo Probar en Simulador iOS

```bash
cd /Users/marco/Proyectos/Pep/mobile_flutter

# Ver simuladores disponibles
flutter devices

# Correr en el simulador iPhone 16e
flutter run -d "D1884CD1-9BB7-4063-AE60-ACF9AC62CF80"
```

Controles en terminal: `r` hot reload · `R` hot restart · `q` salir

```bash
# Abrir en Xcode (para firma/distribución)
open ios/Runner.xcworkspace
```
> ⚠️ Siempre abrir `.xcworkspace`, nunca `.xcodeproj`

---

## Cómo Generar APK Android

```bash
cd /Users/marco/Proyectos/Pep/mobile_flutter
flutter build apk --release
# APK en: build/app/outputs/flutter-apk/app-release.apk (57 MB aprox)
```

---

## Cómo Generar Build iOS (sin firma)

```bash
cd /Users/marco/Proyectos/Pep/mobile_flutter
flutter build ios --no-codesign
# App en: build/ios/iphoneos/Runner.app (20 MB aprox)
```

Para distribuir en App Store: requiere Apple Developer ($99/año) → `flutter build ipa`

---

## Diferencias vs Versión React Native

| Aspecto | React Native / Expo | Flutter |
|---------|---------------------|---------|
| Bundler | Metro (requiere servidor activo) | Sin bundler — compila directo |
| Hot reload | Sí (más lento) | Sí (más rápido) |
| Fotos Android | Problema con `content://` URIs | Sin problema |
| iOS simulator | Timeouts frecuentes | Funciona directo |
| Build Android | `./gradlew assembleRelease` | `flutter build apk` |
| Tamaño APK | ~87 MB | ~57 MB |

---

## Estado Actual

| Feature | Estado |
|---------|--------|
| Auth (login/register) con logo | ✅ |
| Onboarding (sexo + fecha nacimiento) | ✅ |
| Home con altura, sexo, edad | ✅ |
| Peso + cámara/galería + IMC + kg/lbs | ✅ |
| Progreso + filtros período + figura humana | ✅ |
| Recordatorios + calendario | ✅ |
| Sync calendario nativo | ✅ |
| Soporte WhatsApp | ✅ |
| iOS Build | ✅ `flutter build ios --no-codesign` |
| Android APK | ✅ `flutter build apk --release` |
| App Store (iOS) | ⏳ Requiere Apple Developer ($99/año) |
| Google Play (Android) | ⏳ Requiere cuenta Play Console ($25) |

---

## Pendientes

1. Ejecutar migración SQL `11_add_sex_birthdate.sql` en producción (Supabase dashboard)
2. Actualizar número de WhatsApp en `lib/screens/tabs/support_screen.dart`
   ```dart
   static const String _whatsAppNumber = '52XXXXXXXXXX'; // ← cambiar
   ```
3. Si se usa TestFlight: crear App ID y certificado en Apple Developer
