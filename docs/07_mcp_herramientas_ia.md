# Pep Education — MCP Connectors y Herramientas IA

## ¿Qué es MCP?

**Model Context Protocol (MCP)** es un estándar abierto de Anthropic que permite a los modelos de lenguaje (como Claude) conectarse directamente con servicios externos (Supabase, Vercel, GitHub, etc.) sin necesidad de APIs manuales. Los conectores MCP exponen "herramientas" que Claude puede invocar durante una conversación.

---

## MCP Connectors Activos en el Proyecto

### 1. Supabase MCP
- **Propósito:** Ejecutar SQL, gestionar tablas, revisar logs directamente desde Claude Code
- **Proyecto conectado:** `ffuqngbusqmdsezgpztg` (proyecto secundario — NO el de producción)
- **Herramientas disponibles:**
  | Herramienta | Descripción |
  |-------------|-------------|
  | `execute_sql` | Ejecutar queries SQL en el proyecto conectado |
  | `list_tables` | Listar tablas del proyecto |
  | `apply_migration` | Aplicar migraciones DDL |
  | `get_logs` | Ver logs del proyecto |
  | `list_projects` | Ver todos los proyectos Supabase de la cuenta |
  | `create_branch` | Crear branch de base de datos |
  | `generate_typescript_types` | Generar tipos TypeScript desde el schema |
  | `search_docs` | Buscar en documentación de Supabase |
  | `get_advisors` | Ver sugerencias de performance/seguridad |

- **Limitación:** Solo tiene acceso al proyecto `ffuqngbusqmdsezgpztg`. El proyecto de producción `mpdpbfaorquuqvhawwea` requiere usar el SQL Editor del dashboard directamente.

### 2. Vercel MCP
- **Propósito:** Gestionar deployments, ver logs, inspeccionar proyectos en Vercel
- **Herramientas disponibles:**
  | Herramienta | Descripción |
  |-------------|-------------|
  | `list_deployments` | Ver historial de deploys |
  | `get_deployment` | Estado de un deploy específico |
  | `get_deployment_build_logs` | Logs de build |
  | `get_runtime_logs` | Logs de runtime/ejecución |
  | `get_project` | Info del proyecto |
  | `list_projects` | Todos los proyectos |
  | `list_teams` | Teams de Vercel |
  | `deploy_to_vercel` | Hacer deploy |
  | `authenticate` | Autenticarse via OAuth |
  | `check_domain_availability_and_price` | Buscar dominio |
  | `search_vercel_documentation` | Buscar en docs de Vercel |

---

## Herramientas de IA Utilizadas en el Proyecto

### Claude Code (Anthropic)
- **Modelo base:** Claude Sonnet 4.6 (`claude-sonnet-4-6`)
- **Modelos disponibles:**
  | Modelo | ID | Uso recomendado |
  |--------|-----|----------------|
  | Opus 4.6 | `claude-opus-4-6` | Tareas complejas, arquitectura |
  | Sonnet 4.6 | `claude-sonnet-4-6` | Balance calidad/velocidad (default) |
  | Haiku 4.5 | `claude-haiku-4-5-20251001` | Tareas simples, respuestas rápidas |
- **Capacidades usadas:** Lectura de código, edición de archivos, ejecución de comandos bash, análisis de screenshots, MCP tools
- **Sesiones relevantes:** Desarrollo completo del admin web, configuración Supabase, setup Vercel, preparación mobile

### Claude Code — Sub-Agentes Especializados
- **Explore Agent:** Exploración profunda de codebase (audit del proyecto)
- **Plan Agent:** Diseño de planes de implementación
- **Vercel Deployment Expert:** Despliegues y CI/CD en Vercel
- **Vercel AI Architect:** Arquitectura de apps con IA

---

## MCP Connectors Recomendados para Agregar

### GitHub MCP (pendiente configurar)
- **Propósito:** Gestionar PRs, issues, branches, commits directamente desde Claude
- **Paquete:** `@modelcontextprotocol/server-github`
- **Configuración:**
  ```json
  {
    "name": "github",
    "command": "npx",
    "args": ["@modelcontextprotocol/server-github"],
    "env": {
      "GITHUB_PERSONAL_ACCESS_TOKEN": "<tu token de GitHub>"
    }
  }
  ```

### Filesystem MCP (disponible localmente)
- **Propósito:** Acceso seguro al sistema de archivos del proyecto
- **Herramientas:** read_file, write_file, list_directory, search_files

---

## Configuración de Claude Code

### Archivos de configuración relevantes
```
~/.claude/
├── settings.json          # Configuración global de Claude Code
├── settings.local.json    # Configuración local (no se comparte)
└── projects/
    └── -Users-marco-Proyectos-Pep/
        └── memory/        # Memoria persistente del proyecto
            ├── MEMORY.md              # Índice de memorias
            ├── project_overview.md    # Overview del proyecto
            ├── project_supabase.md    # Config Supabase
            ├── user_profile.md        # Perfil del usuario
            ├── feedback_rules.md      # Reglas de colaboración
            └── project_darkmode.md    # Pendiente dark mode
```

### Sistema de Memoria Persistente
Claude Code mantiene memoria entre sesiones del proyecto:
- **user:** Perfil de Marco (roles, preferencias, nivel técnico)
- **feedback:** Reglas aprendidas sobre cómo colaborar
- **project:** Estado actual del proyecto, decisiones tomadas
- **reference:** Dónde encontrar información en sistemas externos

---

## Flujo de Trabajo con IA (Recomendado)

### Para desarrollo de features nuevas:
```
1. Describir la feature a Claude Code en lenguaje natural
2. Claude revisa el código existente antes de proponer cambios
3. Claude implementa los cambios (Edit/Write tools)
4. Revisar los cambios antes de commitear
5. Claude puede hacer el commit y push si se autoriza
```

### Para debugging:
```
1. Compartir screenshot del error con Claude Code
2. Claude analiza la imagen + los logs del código
3. Claude propone y aplica el fix
4. Verificar que funciona
```

### Para deploys:
```
1. Claude verifica que el build local funciona (npm run build)
2. Claude hace git push → Vercel auto-deploys
3. Claude verifica el deploy via MCP Vercel
4. Si hay errores: Claude revisa build logs via MCP
```

---

## APIs y SDKs Utilizados

### Supabase JavaScript Client
- **Paquete:** `@supabase/supabase-js ^2.100.1`
- **Documentación:** https://supabase.com/docs/reference/javascript
- **Métodos principales usados:**
  ```typescript
  supabase.auth.signInWithPassword()
  supabase.auth.signUp()
  supabase.auth.verifyOtp()
  supabase.auth.signOut()
  supabase.auth.updateUser()
  supabase.auth.resetPasswordForEmail()
  supabase.auth.onAuthStateChange()
  supabase.from('tabla').select()
  supabase.from('tabla').insert()
  supabase.from('tabla').update()
  supabase.storage.from('bucket').upload()
  supabase.storage.from('bucket').getPublicUrl()
  ```

### Vercel API (via MCP)
- **SDK:** `@vercel/sdk` (disponible si se necesita programáticamente)
- **MCP Plugin:** `plugin:vercel-plugin:env`, `plugin:vercel-plugin:deployment-expert`

### EAS CLI
- **Paquete:** `eas-cli` (instalar globalmente: `npm i -g eas-cli`)
- **Comandos principales:**
  ```bash
  eas login                              # Autenticarse
  eas init                              # Inicializar proyecto
  eas build --platform android          # Build Android
  eas build --platform ios              # Build iOS
  eas build --platform all             # Ambas plataformas
  eas submit --platform android         # Submit a Play Store
  eas submit --platform ios             # Submit a App Store
  eas update                            # OTA update (sin rebuild)
  ```

### Expo SDK
- **Versión:** ~54.0.33
- **Documentación:** https://docs.expo.dev
- **Plugins utilizados:**
  - `expo-router`: Navegación file-based
  - `expo-image-picker`: Selección de fotos
  - `expo-splash-screen`: Pantalla de carga
  - `expo-haptics`: Feedback táctil
  - `expo-constants`: Constantes del dispositivo
  - `expo-font`: Carga de fuentes custom
  - `expo-linking`: Deep links

---

## Recursos de Documentación

| Recurso | URL |
|---------|-----|
| Supabase Docs | https://supabase.com/docs |
| Next.js Docs | https://nextjs.org/docs |
| Expo Docs | https://docs.expo.dev |
| EAS Build | https://docs.expo.dev/build/introduction |
| EAS Submit | https://docs.expo.dev/submit/introduction |
| Vercel Docs | https://vercel.com/docs |
| Tailwind CSS v4 | https://tailwindcss.com/docs |
| React Native | https://reactnative.dev/docs |
| Expo Router | https://docs.expo.dev/router/introduction |
| Apple Developer | https://developer.apple.com/documentation |
| Google Play Console Help | https://support.google.com/googleplay/android-developer |
| MCP Protocol | https://modelcontextprotocol.io |
| Claude Code Docs | https://docs.anthropic.com/claude-code |
