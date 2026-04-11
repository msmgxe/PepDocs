# Pep Education — App Móvil (Detalle Técnico)

## Configuración del Proyecto

| Parámetro | Valor |
|-----------|-------|
| **Framework** | Expo 54 (React Native 0.81.5) |
| **Lenguaje** | TypeScript 5 |
| **Routing** | Expo Router v6 (file-based) |
| **Package name** | `com.pepeducation.app` |
| **App name** | PepEducation |
| **Slug** | PepEducation |
| **Deep link scheme** | `pepeducation://` |
| **Nueva arquitectura** | Habilitada (`newArchEnabled: true`) |
| **Orientación** | Portrait únicamente |
| **Interfaz** | Light + Dark mode automático (`userInterfaceStyle: "automatic"`) |

---

## Estructura de Archivos

```
mobile/
├── app/
│   ├── _layout.tsx              # Root: AuthProvider, fonts, routing lógico
│   ├── (auth)/
│   │   ├── _layout.tsx          # Stack navigator auth
│   │   ├── login.tsx            # Pantalla login (email + pass)
│   │   ├── register.tsx         # Registro (nombre, email, pass, confirmación)
│   │   ├── verify.tsx           # Verificación OTP (6 dígitos)
│   │   └── callback.tsx         # Handler OAuth redirect (magic links)
│   ├── (onboarding)/
│   │   ├── _layout.tsx          # Stack navigator onboarding
│   │   └── index.tsx            # Wizard 6 pasos (teléfono, peso, altura, edad, sexo, meds)
│   └── (tabs)/
│       ├── _layout.tsx          # Bottom tab navigator (5 tabs, support oculto)
│       ├── index.tsx            # Home: bienvenida, próxima cita, tips, notas
│       ├── weight.tsx           # Registro de peso + gráfico SVG + zoom
│       ├── progress.tsx         # LineChart progreso + achievement badges
│       ├── calendar.tsx         # Calendario mensual + crear/ver eventos
│       └── support.tsx          # Centro de soporte + contacto médico
├── context/
│   └── AuthContext.tsx          # Sesión, perfil, hasProfile, routing
├── lib/
│   └── supabase.ts              # Cliente Supabase con AsyncStorage
├── constants/
│   └── theme.ts                 # Colores light/dark + fonts por plataforma
├── hooks/
│   ├── use-color-scheme.ts      # Re-export de useColorScheme
│   └── use-color-scheme.web.ts  # Fix de hidratación para web
├── assets/
│   └── images/
│       ├── icon.png                       # Ícono de la app (1024×1024 recomendado)
│       ├── splash-icon.png                # Imagen splash screen
│       ├── favicon.png                    # Para versión web
│       ├── android-icon-foreground.png    # Ícono adaptativo Android (capa frontal)
│       ├── android-icon-background.png    # Ícono adaptativo Android (fondo)
│       └── android-icon-monochrome.png    # Ícono monocromático Android 13+
├── app.json                     # Configuración Expo
├── eas.json                     # Configuración EAS Build
├── .env                         # Variables de entorno (NO en GitHub)
├── .gitignore
├── expo-env.d.ts                # Tipos generados por Expo
├── tsconfig.json
└── package.json
```

---

## Flujo de Navegación

```
App Launch
    │
    ├── [Cargando fuentes + verificando sesión]
    │
    ├── Sin sesión → (auth)/login
    │                    ├── Login exitoso + tiene perfil → (tabs)/
    │                    ├── Login exitoso + sin perfil → (onboarding)/
    │                    └── Sin cuenta → register → verify → (onboarding)/
    │
    └── Con sesión
            ├── hasProfile = true → (tabs)/
            └── hasProfile = false → (onboarding)/

(onboarding)/ [6 pasos]
    1. Teléfono
    2. Peso actual + Peso meta
    3. Altura (cm o pies)
    4. Edad
    5. Sexo
    6. Medicamentos actuales
    → Guarda en profiles → redirige a (tabs)/

(tabs)/
    ├── index (Home) ←→ weight ←→ progress ←→ calendar
    └── support (href: null — accesible desde Home, no en nav)
```

---

## AuthContext — Manejo de Estado de Auth

```typescript
// mobile/context/AuthContext.tsx
interface AuthContextType {
  session: Session | null;         // Sesión de Supabase (JWT + refresh token)
  profile: Profile | null;         // Datos del perfil del usuario
  hasProfile: boolean;             // ¿Completó el onboarding?
  loading: boolean;                // Cargando sesión inicial
  refreshProfile: () => Promise<void>;  // Actualizar datos del perfil
}

// Importante: refreshProfile() debe llamarse SOLO al final del flujo de onboarding,
// NO durante la grabación de datos intermedios.
// Si se llama antes, TOKEN_REFRESHED dispara hasProfile=true prematuramente
// y el layout redirige antes de que el usuario vea la pantalla final de onboarding.
```

---

## Cliente Supabase Mobile

```typescript
// mobile/lib/supabase.ts
import { createClient } from '@supabase/supabase-js';
import AsyncStorage from '@react-native-async-storage/async-storage';

export const supabase = createClient(
  process.env.EXPO_PUBLIC_SUPABASE_URL!,
  process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!,
  {
    auth: {
      storage: AsyncStorage,           // Persistencia de sesión nativa
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,       // NO usar flowType: 'pkce' — rompe React Native
    },
  }
);
```

> ⚠️ **Importante:** NO agregar `flowType: 'pkce'` al cliente de mobile. El PKCE flow está pensado para web y causa problemas en React Native con el manejo de URLs.

---

## Sistema de Temas (Light/Dark Mode)

```typescript
// mobile/constants/theme.ts
export const Colors = {
  light: {
    primary: '#7B2D8B',
    primaryMid: '#C4A2DC',
    primaryPale: '#F4EDF8',
    accent: '#FFD700',
    background: '#FFFFFF',
    surface: '#F9FAFB',
    text: '#1A1A1A',
    textSecondary: '#6B7280',
    border: '#E5E7EB',
  },
  dark: {
    primary: '#A855CC',
    primaryMid: '#7B2D8B',
    primaryPale: '#2D1B35',
    accent: '#FFD700',
    background: '#0F0F0F',
    surface: '#1A1A1A',
    text: '#F9FAFB',
    textSecondary: '#9CA3AF',
    border: '#374151',
  },
};

// Uso en screens:
// const colorScheme = useColorScheme();
// const colors = Colors[colorScheme ?? 'light'];
```

---

## Variables de Entorno Mobile

Archivo `.env` (en `mobile/` — NO commitear a GitHub):

```bash
EXPO_PUBLIC_SUPABASE_URL=https://mpdpbfaorquuqvhawwea.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=<anon key del proyecto>
```

> El prefijo `EXPO_PUBLIC_` es requerido para que las variables sean accesibles en el bundle de la app. Variables sin este prefijo son solo para el proceso de build (no disponibles en runtime de la app).

---

## Dependencias Completas

```json
{
  "dependencies": {
    "@expo/vector-icons": "^15.0.3",
    "@react-native-async-storage/async-storage": "2.2.0",
    "@react-navigation/bottom-tabs": "^7.4.0",
    "@react-navigation/elements": "^2.6.3",
    "@react-navigation/native": "^7.1.8",
    "@supabase/supabase-js": "^2.100.1",
    "expo": "~54.0.33",
    "expo-constants": "~18.0.13",
    "expo-font": "~14.0.11",
    "expo-haptics": "~15.0.8",
    "expo-image": "~3.0.11",
    "expo-image-picker": "~17.0.10",
    "expo-linking": "~8.0.11",
    "expo-router": "~6.0.23",
    "expo-splash-screen": "~31.0.13",
    "expo-status-bar": "~3.0.9",
    "expo-symbols": "~1.0.8",
    "expo-system-ui": "~6.0.9",
    "expo-web-browser": "~15.0.10",
    "react": "19.1.0",
    "react-dom": "19.1.0",
    "react-native": "0.81.5",
    "react-native-chart-kit": "^6.12.0",
    "react-native-gesture-handler": "~2.28.0",
    "react-native-reanimated": "~4.1.1",
    "react-native-safe-area-context": "~5.6.0",
    "react-native-screens": "~4.16.0",
    "react-native-svg": "15.12.1",
    "react-native-url-polyfill": "^3.0.0",
    "react-native-web": "~0.21.0",
    "react-native-worklets": "0.5.1"
  }
}
```

---

## Comandos de Desarrollo

```bash
cd /Users/marco/Proyectos/Pep/mobile

# Instalar dependencias
npm install

# Servidor de desarrollo (con Expo Go o dev client)
npx expo start

# Correr en simulador iOS (requiere Xcode en Mac)
npx expo run:ios

# Correr en emulador Android (requiere Android Studio)
npx expo run:android

# Build de desarrollo (para testear en dispositivo real)
npx eas build --platform ios --profile development
npx eas build --platform android --profile development

# Build de producción
npx eas build --platform ios --profile production
npx eas build --platform android --profile production

# Actualización OTA (sin rebuild completo — cambios de JS/assets)
npx eas update --branch production --message "Fix: descripción del cambio"
```

---

## Features Implementadas

| Feature | Pantalla | Estado |
|---------|----------|--------|
| Login email/password | (auth)/login | ✅ |
| Registro de usuario | (auth)/register | ✅ |
| Verificación OTP | (auth)/verify | ✅ |
| Onboarding 6 pasos | (onboarding)/index | ✅ |
| Dashboard Home | (tabs)/index | ✅ |
| Registro de peso | (tabs)/weight | ✅ |
| Gráfico de progreso | (tabs)/weight | ✅ (SVG + pinch-zoom) |
| Filtros temporales gráfico | (tabs)/weight | ✅ (1M, 3M, 6M, Todo) |
| Subida de foto de peso | (tabs)/weight | ✅ (image picker) |
| Achievements/badges | (tabs)/progress | ✅ |
| LineChart progreso | (tabs)/progress | ✅ (react-native-chart-kit) |
| Calendario de citas | (tabs)/calendar | ✅ |
| Crear eventos | (tabs)/calendar | ✅ |
| Contacto médico (WhatsApp) | (tabs)/support | ✅ |
| FAQ | (tabs)/support | ⏳ Placeholder |
| Dark mode | Todas | ✅ |
| Push notifications | - | ❌ No implementado |
| Biometría/Face ID | - | ❌ No implementado |

---

## Problemas Conocidos y Soluciones

| Problema | Causa | Solución |
|---------|-------|----------|
| `flowType: 'pkce'` causa crashes | PKCE no es compatible con React Native URL handling | Eliminar `flowType: 'pkce'` del cliente Supabase mobile |
| `refreshProfile()` llamado temprano causa redirect prematuro | `TOKEN_REFRESHED` event dispara `hasProfile=true` | Llamar `refreshProfile()` SOLO al final del onboarding, en el tap final del usuario |
| Iconos aparecen como `[?]` en simulador | MaterialCommunityIcons con texto emoji | Usar solo componentes de icono de `@expo/vector-icons`, no caracteres emoji |
| App no encuentra variables de entorno | Falta prefijo `EXPO_PUBLIC_` | Todas las vars de entorno accesibles en runtime deben tener `EXPO_PUBLIC_` |
| Fecha de cita se graba un día antes | `new Date("2026-04-10")` parsea como UTC midnight → en zona horaria local (-N horas) es el día anterior | Añadir `T12:00:00` al parsear: `new Date(e.event_date + 'T12:00:00')` — afecta `eventDays`, `displayedEvents`, `openEditModal` y el display de fechas |
| Foto no tiene botón de confirmar tras captura | `allowsEditing: true` en `ImagePicker` muestra UI de recorte nativa de Android que no siempre tiene botón visible | Establecer `allowsEditing: false` en `launchCameraAsync` y `launchImageLibraryAsync` — la foto se acepta directamente al seleccionarla |
