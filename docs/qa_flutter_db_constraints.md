# QA — Compatibilidad Flutter ↔ Supabase `profiles`

**Fecha:** 2026-04-13  
**Proyecto Supabase (prod):** `mpdpbfaorquuqvhawwea`  
**Flutter:** 3.41.6 / Dart

---

## Constraints verificados en DB (tabla `profiles`)

| Constraint | Definición |
|---|---|
| `profiles_sex_check` | `CHECK (sex = ANY (ARRAY['femenino', 'masculino']))` |
| `profiles_role_check` | `CHECK (role = ANY (ARRAY['usuario', 'admin', 'patient']))` |
| `profiles_notes_check` | `CHECK (char_length(notes) <= 250)` |
| `profile_notes_length` | `CHECK (char_length(profile_notes) <= 250)` |
| `email` | NOT NULL |
| `full_name` | NOT NULL |

**Columnas de peso correctas:** `current_weight_kg`, `goal_weight_kg`  
**Columnas con DEFAULT (no requieren envío):** `registration_date`, `is_active`, `role`, `created_at`, `updated_at`

---

## Resultado por archivo

| Archivo | Estado | Detalle |
|---|---|---|
| `supabase_service.dart` | **PASS** | `email` incluido en INSERT; UPDATE no modifica auth_uid ni email |
| `onboarding_screen.dart` | **PASS** | sex: `'masculino'`/`'femenino'` ✓; columnas: `current_weight_kg`/`goal_weight_kg` ✓; role: `'patient'` válido ✓ |
| `profile_screen.dart` | **PASS** | sex: `'masculino'`/`'femenino'` ✓; columnas de peso correctas ✓ |
| `home_screen.dart` | **PASS** | Solo lectura; comparación `sex == 'femenino'` ✓; lee `current_weight_kg`/`goal_weight_kg` ✓ |
| `progress_screen.dart` | **PASS** | Solo lectura; `isFemale = sex == 'femenino'` ✓; lee `goal_weight_kg`/`current_weight_kg` ✓ |
| `main.dart` | **PASS** | Sin writes a DB; inicialización Supabase correcta |

---

## Valores enviados a `profiles` en cada operación

### INSERT — primer onboarding (`upsertProfile`)

| Campo | Valor |
|---|---|
| `full_name` | texto ingresado por el usuario |
| `current_weight_kg` | decimal ingresado |
| `goal_weight_kg` | decimal ingresado |
| `height_cm` | decimal ingresado |
| `role` | `'patient'` (hardcoded — válido en constraint) |
| `sex` | `'masculino'` o `'femenino'` (opcional) |
| `birth_date` | `YYYY-MM-DD` (opcional) |
| `auth_uid` | `user.id` del auth |
| `email` | `user.email` del auth |

### UPDATE — pantalla Mi Perfil (`upsertProfile`)

| Campo | Valor |
|---|---|
| `full_name` | texto ingresado |
| `height_cm` | decimal |
| `current_weight_kg` | decimal |
| `goal_weight_kg` | decimal |
| `sex` | `'masculino'` o `'femenino'` (opcional) |
| `birth_date` | `YYYY-MM-DD` (opcional) |

---

## Bugs corregidos en esta sesión

| # | Error | Causa raíz | Corrección |
|---|---|---|---|
| 1 | `PGRST204 target_weight_kg` | Columna no existe; DB usa `goal_weight_kg` | Renombrado en 4 archivos |
| 2 | `PGRST204 weight_kg` (profiles) | Columna no existe; DB usa `current_weight_kg` | Renombrado en 4 archivos |
| 3 | `null value in column "email"` | INSERT no incluía email (NOT NULL) | Agregado en `upsertProfile` insert |
| 4 | `profiles_sex_check` constraint | Código enviaba `'male'`/`'female'`; DB espera `'masculino'`/`'femenino'` | Valores corregidos en 4 archivos |

---

## Resultados de build

| Plataforma | Resultado | Tamaño |
|---|---|---|
| Android APK (release) | **✓ BUILD OK** | 57.4 MB |
| iOS (no-codesign) | **✓ BUILD OK** | 20.1 MB |

```
flutter analyze --no-fatal-infos → No issues found
```

---

## Veredicto

**LISTO PARA PRUEBAS EN DISPOSITIVO**

Todos los valores enviados a la tabla `profiles` son compatibles con los constraints de la DB.  
`flutter analyze` sin errores. Ambas plataformas compilan correctamente.
