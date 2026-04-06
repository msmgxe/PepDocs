# Pep Education — Admin Web (Next.js + Vercel)

## Información del Proyecto

| Parámetro | Valor |
|-----------|-------|
| **Framework** | Next.js 16.2.1 (App Router) |
| **Runtime** | Node.js 24.x |
| **Lenguaje** | TypeScript 5 |
| **Estilos** | Tailwind CSS 4.2.2 |
| **Deploy** | Vercel (Hobby Plan — gratis) |
| **URL producción** | https://pepeducation-admin.vercel.app |
| **GitHub repo** | https://github.com/msmgxe/pepeducation-admin |
| **Vercel Project ID** | `prj_ION10LpJk14WbOv523RIhgo6eclb` |
| **Vercel Org ID** | `team_BEnERBBIE9R2QUBlV90RjOQ5` |
| **Vercel Project Name** | `pepeducation-admin` |

---

## Estructura de Archivos

```
admin/
├── src/
│   ├── app/
│   │   ├── layout.tsx                 # Root layout (html, body, fonts)
│   │   ├── globals.css                # Estilos globales + Tailwind
│   │   ├── (auth)/                    # Rutas sin sidebar (standalone)
│   │   │   ├── layout.tsx             # Layout vacío: return <>{children}</>
│   │   │   └── login/
│   │   │       └── page.tsx           # Pantalla de login
│   │   └── (app)/                     # Rutas con sidebar (autenticadas)
│   │       ├── layout.tsx             # Sidebar + Header + BottomNav mobile (usa LayoutShell)
│   │       ├── page.tsx               # Dashboard principal
│   │       ├── usuarios/
│   │       │   └── page.tsx           # Lista y gestión de pacientes
│   │       ├── calendario/
│   │       │   └── page.tsx           # Calendario de citas
│   │       ├── analisis/
│   │       │   └── page.tsx           # Análisis clínico Tirzepatide + Simulador modal
│   │       ├── whatsapp/
│   │       │   └── page.tsx           # Broadcasting masivo
│   │       └── update-password/
│   │           └── page.tsx           # Cambio de contraseña (admin)
│   ├── components/
│   │   └── layout/
│   │       ├── layout-shell.tsx       # Client Component: flex container con sidebar position
│   │       ├── header-bar.tsx         # Header: búsqueda, notificaciones, preferencias
│   │       └── logout-button.tsx      # Botón de cierre de sesión
│   └── lib/
│       ├── supabase.ts                # Inicialización cliente Supabase
│       └── utils.ts                   # Helper: cn() para clases Tailwind
├── public/                            # Assets estáticos
├── .env.local                         # Variables de entorno locales (NO commitear)
├── .env.local.example                 # Template sin valores sensibles
├── next.config.ts                     # Configuración de Next.js
├── tailwind.config.ts                 # Configuración de Tailwind (darkMode: 'class')
├── tsconfig.json                      # Configuración TypeScript
└── package.json                       # Dependencias
```

---

## Variables de Entorno

### En desarrollo local (archivo `.env.local`)
```bash
NEXT_PUBLIC_SUPABASE_URL=https://mpdpbfaorquuqvhawwea.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon key del proyecto Supabase>
```

### En Vercel (Settings → Environment Variables)

| Variable | Environments | Descripción |
|----------|-------------|-------------|
| `NEXT_PUBLIC_SUPABASE_URL` | Production, Preview, Development | URL del proyecto Supabase |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Production, Preview, Development | Anon key pública de Supabase |

> ⚠️ **Lección crítica:** Al ingresar `NEXT_PUBLIC_SUPABASE_URL` en Vercel, verificar SIEMPRE que el Project ID sea `mpdpbfaorquuqvhawwea` (con doble `u` antes de la `q`). Un typo aquí causa `ERR_NAME_NOT_RESOLVED` en todos los llamados de auth.

---

## Páginas del Admin

### `/` — Dashboard
- **KPIs:** Total usuarios, Actividad (%), Peso perdido (kg), Planes activos
- **Selector temporal:** Semana / Mes con navegación ←→
- **Tabla:** Usuarios recientes con nombre, peso actual, balance y acciones
- **Alertas dinámicas:** Notificaciones de pacientes con variaciones importantes

### `/usuarios` — Gestión de Pacientes
- Lista paginada de todos los pacientes
- Búsqueda por nombre/email
- Ver detalle: mediciones, notas, historial
- Editar notas del médico

### `/calendario` — Citas y Eventos
- Vista mensual de calendario
- Crear evento modal (título, descripción, fecha, paciente)
- Lista de eventos del día seleccionado

### `/analisis` — Análisis Clínico
- Gráfico de evolución de peso con rangos clínicos de Tirzepatide (SVG puro)
- Comparación peso real vs. curva clínica esperada (SURMOUNT-1)
- Tabla de historial de pesajes
- **Simulador** (botón morado): modal con input de semana, calcula pérdida esperada vs. real y muestra gráfica comparativa SVG interactiva

### `/whatsapp` (Broadcasting) — Mensajes Masivos
- Composición de mensaje de texto
- Adjuntar imagen (sube a bucket `broadcasts` en Storage)
- Seleccionar pacientes destinatarios
- Envío masivo (integración con WhatsApp Business API o simulado)

### `/login` — Autenticación
- Formulario: email + contraseña
- CAPTCHA matemático (generado en cliente, no server-side)
  - Operaciones: suma, resta, multiplicación de 1-9
  - Hydration fix: `useState(null)` + `useEffect(() => setCaptcha(makeCaptcha()), [])`
- Verificación de rol `admin` en tabla `profiles` post-login
- Si no es admin: `signOut()` automático + mensaje de error

---

## Inicialización del Cliente Supabase

```typescript
// admin/src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);
```

---

## Flujo de Deploy

### Deploy automático (rama main → Vercel)
```
git add .
git commit -m "feat: descripción del cambio"
git push origin main
# Vercel detecta el push y despliega automáticamente (~1-2 min)
```

> ⚠️ **Crítico:** El git `user.email` debe estar configurado como la cuenta de GitHub para que Vercel acepte el commit. Si el email local no coincide con ningún usuario de GitHub, Vercel bloquea el deploy con "could not associate the committer with a GitHub user".
>
> Configuración correcta para este repo:
> ```bash
> git config user.email "msmgxe@users.noreply.github.com"
> git config user.name "msmgxe"
> ```

### Deploy manual desde CLI
```bash
# Instalar Vercel CLI primero
npm i -g vercel

# Desde la carpeta admin/
cd admin
vercel --prod
```

### Verificar deploy en Vercel
```bash
vercel ls                    # Lista deployments
vercel logs <deployment-id>  # Ver logs de un deploy
```

---

## Comandos de Desarrollo

```bash
cd admin

# Instalar dependencias
npm install

# Servidor de desarrollo (http://localhost:3000)
npm run dev

# Build de producción (verificar errores antes de pushear)
npm run build

# Linter
npm run lint
```

---

## Configuración Git (para referencia)

```bash
# Remote configurado con token de autenticación
git remote set-url origin https://TOKEN@github.com/msmgxe/pepeducation-admin.git

# Ver remoto actual
git remote -v

# Push normal
git push origin main
```

> **Nota:** El token de GitHub expira. Si el push falla con 401/403, generar nuevo token en GitHub → Settings → Developer Settings → Personal Access Tokens → Tokens (classic) → New token → scope: `repo`.

---

## Vercel — Configuración MCP

El proyecto tiene integración MCP con Vercel para gestionar deployments desde Claude Code:

```json
// Herramientas disponibles vía MCP Vercel:
// - list_deployments: Ver historial de deploys
// - get_deployment: Estado de un deploy específico
// - get_deployment_build_logs: Logs de build
// - get_runtime_logs: Logs de runtime
// - get_project: Info del proyecto
// - list_projects: Todos los proyectos
```

Para autenticarse: usar `mcp__plugin_vercel-plugin_vercel__authenticate` desde Claude Code.

---

## Dependencias del Proyecto Admin

```json
{
  "dependencies": {
    "@supabase/supabase-js": "^2.100.1",  // Cliente Supabase
    "lucide-react": "^1.7.0",             // Iconos SVG
    "next": "16.2.1",                     // Framework
    "react": "19.2.4",
    "react-dom": "19.2.4"
  },
  "devDependencies": {
    "@tailwindcss/postcss": "^4.2.2",
    "@types/node": "^20",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "autoprefixer": "^10.4.27",
    "eslint": "^9",
    "eslint-config-next": "16.2.1",
    "postcss": "^8.5.8",
    "tailwindcss": "^4.2.2",
    "typescript": "^5"
  }
}
```

---

## Credenciales de Acceso al Admin

| Campo | Valor |
|-------|-------|
| **URL** | https://pepeducation-admin.vercel.app/login |
| **Email** | `masm.a@outlook.com` |
| **Contraseña** | `PepAdmin2026` |
| **Rol** | admin |

> ⚠️ Cambiar la contraseña periódicamente por seguridad. Para cambiarla: ingresar al admin, ir a `/update-password`.
