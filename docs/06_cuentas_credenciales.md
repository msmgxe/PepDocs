# Pep Education — Cuentas, Credenciales y Parámetros

> ⚠️ **DOCUMENTO CONFIDENCIAL** — No compartir públicamente. No subir a repositorios públicos de GitHub. Guardar copia segura offline (ej: Bitwarden, 1Password, o papel físico en lugar seguro).

---

## Resumen de Cuentas

| Servicio | Email/Usuario | Contraseña | Estado |
|---------|--------------|-----------|--------|
| Supabase (propietario) | `adrian.si.msam@gmail.com` | (propia de Adrian) | ✅ Activo |
| Admin Web (usuario admin) | `masm.a@outlook.com` | `PepAdmin2026` | ✅ Activo |
| Vercel | (cuenta vinculada) | (propia) | ✅ Activo |
| GitHub | `msmgxe` | (propia) | ✅ Activo |
| EAS / expo.dev | ❌ Pendiente crear | - | ⏳ |
| Google Play Console | ❌ Pendiente crear | - | ⏳ |
| Apple Developer Program | ❌ Pendiente crear | - | ⏳ |

---

## Supabase

### Proyecto Principal (PRODUCCIÓN)
| Parámetro | Valor |
|-----------|-------|
| **Project ID** | `mpdpbfaorquuqvhawwea` |
| **Project Name** | PepEducation |
| **URL** | `https://mpdpbfaorquuqvhawwea.supabase.co` |
| **Propietario** | `adrian.si.msam@gmail.com` |
| **Plan** | FREE |
| **Dashboard** | https://supabase.com/dashboard/project/mpdpbfaorquuqvhawwea |

### Keys del Proyecto
| Key | Tipo | Dónde obtenerla |
|-----|------|----------------|
| `anon` key | Pública (safe para frontend) | Supabase → Settings → API → anon public |
| `service_role` key | Privada (NUNCA en frontend) | Supabase → Settings → API → service_role |

> Para ver las keys: Supabase Dashboard → Settings → API → "Project API keys"

---

## Vercel

| Parámetro | Valor |
|-----------|-------|
| **Project Name** | `pepeducation-admin` |
| **Project ID** | `prj_ION10LpJk14WbOv523RIhgo6eclb` |
| **Org/Team ID** | `team_BEnERBBIE9R2QUBlV90RjOQ5` |
| **URL producción** | https://pepeducation-admin.vercel.app |
| **Dashboard** | https://vercel.com/dashboard |
| **Plan** | Hobby (gratis) |
| **Framework detectado** | Next.js |
| **Node version** | 24.x |

### Variables de Entorno en Vercel
| Variable | Environments | Descripción |
|----------|-------------|-------------|
| `NEXT_PUBLIC_SUPABASE_URL` | Production, Preview, Development | `https://mpdpbfaorquuqvhawwea.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Production, Preview, Development | Anon key del proyecto Supabase |

> ⚠️ **Typo histórico:** El valor de `NEXT_PUBLIC_SUPABASE_URL` fue ingresado con un typo una vez (`mpdpbfaorquqvhawwea` sin una `u`). Siempre verificar que tenga exactamente `mpdpbfaorquuqvhawwea`.

---

## GitHub

| Parámetro | Valor |
|-----------|-------|
| **Username** | `msmgxe` |
| **Repositorio admin** | https://github.com/msmgxe/pepeducation-admin |
| **Rama principal** | `main` |
| **Visibilidad** | (revisar si es público o privado) |

### Personal Access Token (GitHub)
- Se genera en: GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
- Scope necesario: `repo` (acceso completo a repositorios)
- Los tokens expiran — si el push falla, generar uno nuevo

Para configurar el remote con token:
```bash
git remote set-url origin https://USUARIO:TOKEN@github.com/msmgxe/pepeducation-admin.git
```

---

## Admin Web — Credenciales de Acceso

| Campo | Valor |
|-------|-------|
| **URL** | https://pepeducation-admin.vercel.app/login |
| **Email** | `masm.a@outlook.com` |
| **Contraseña actual** | `PepAdmin2026` |
| **Rol en DB** | admin |
| **Cómo cambiar contraseña** | Ir a `/update-password` mientras estás logueado |

### Historial de contraseñas (para referencia)
| Fecha | Contraseña | Método de cambio |
|-------|-----------|-----------------|
| Abril 2026 | `Papucho123` → `PepAdmin2026` | updateUser() vía DevTools Console + recovery email |

---

## App Móvil — Identificadores

| Parámetro | Valor |
|-----------|-------|
| **App name** | PepEducation |
| **Slug** | PepEducation |
| **Bundle ID / Package** | `com.pepeducation.app` |
| **Deep link scheme** | `pepeducation://` |
| **EAS Project ID** | ⏳ Se genera al ejecutar `eas init` |

---

## Cuentas Pendientes de Crear

### EAS / expo.dev (GRATIS)
- **URL de registro:** https://expo.dev/signup
- **Recomendación:** Usar email `masm.a@outlook.com` para coherencia
- **Guardar:** email + contraseña

### Google Play Console ($25 único)
- **URL:** https://play.google.com/console
- **Pago:** $25 USD con tarjeta
- **Información necesaria:** Nombre completo o empresa, dirección, teléfono
- **Guardar:** Email Google utilizado + contraseña

### Apple Developer Program ($99/año)
- **URL:** https://developer.apple.com/programs/enroll/
- **Pago:** $99 USD/año con tarjeta o PayPal
- **Información necesaria:** Apple ID, nombre real, país
- **Guardar:** Apple ID + contraseña + datos de renovación anual
- **IDs importantes post-registro:**
  - **Team ID:** 10 caracteres (ej: `AB12CD34EF`) — ver en Membership
  - **App Store Connect App ID:** número largo (ej: `1234567890`) — ver en URL de App Store Connect

---

## Variables de Entorno — Referencia Completa

### Admin Web (`.env.local`)
```bash
NEXT_PUBLIC_SUPABASE_URL=https://mpdpbfaorquuqvhawwea.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<obtener de Supabase Settings → API>
```

### Mobile (`.env`)
```bash
EXPO_PUBLIC_SUPABASE_URL=https://mpdpbfaorquuqvhawwea.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=<obtener de Supabase Settings → API>
```

### Mobile — EAS Secrets (configurar en expo.dev si se necesitan en el build)
```bash
# Solo si se implementan notificaciones push:
FIREBASE_SERVER_KEY=<obtener de Firebase Console>
```

### Mobile — Google Play Submit
```
# google-play-key.json → en /mobile/ → NO en GitHub
# Archivo JSON de Service Account de Google Cloud
# Ver instrucciones en 04_mobile_android.md
```

---

## URLs Importantes de Referencia

| Servicio | URL |
|---------|-----|
| Admin web producción | https://pepeducation-admin.vercel.app |
| Supabase dashboard | https://supabase.com/dashboard/project/mpdpbfaorquuqvhawwea |
| Supabase Auth users | https://supabase.com/dashboard/project/mpdpbfaorquuqvhawwea/auth/users |
| Supabase SQL Editor | https://supabase.com/dashboard/project/mpdpbfaorquuqvhawwea/sql |
| Supabase Storage | https://supabase.com/dashboard/project/mpdpbfaorquuqvhawwea/storage/buckets |
| Supabase API Keys | https://supabase.com/dashboard/project/mpdpbfaorquuqvhawwea/settings/api |
| Vercel dashboard | https://vercel.com/dashboard |
| GitHub repo admin | https://github.com/msmgxe/pepeducation-admin |
| EAS builds | https://expo.dev (una vez creada la cuenta) |
| Google Play Console | https://play.google.com/console |
| App Store Connect | https://appstoreconnect.apple.com |
| Apple Developer | https://developer.apple.com/account |

---

## Política de Seguridad

1. **Nunca** subir `.env.local`, `.env`, `google-play-key.json` a GitHub (ya están en `.gitignore`)
2. **Nunca** exponer la `service_role` key de Supabase en el frontend
3. La `anon` key sí puede estar en el frontend (es pública por diseño)
4. Cambiar la contraseña del admin web periódicamente
5. Usar contraseñas distintas para cada servicio
6. Activar 2FA en GitHub, Supabase, Apple Developer y Google Play Console
