# Guía de Deploy — ModalA

## Flujo normal (cualquier cambio de código)

Simplemente haz push a `main` y GitHub Actions despliega automáticamente:

```powershell
git add .
git commit -m "descripcion del cambio"
git push origin main
```

- Cambios en `backend-sw1-final/` → se redespliega el backend en Azure Container Apps
- Cambios en `frontend-web/` → se redespliega el frontend en Azure Static Web Apps
- Cambios en `python-service/` → se redespliega el AI service en Azure Container Apps

Puedes ver el progreso en: **GitHub → Actions**

---

## Cambios en el schema de base de datos (schema.prisma)

Cuando modifiques `schema.prisma`, debes crear y aplicar la migración manualmente:

```powershell
cd "c:\Users\ventu\OneDrive\Desktop\PROYECTO GRUPAL\backend-sw1-final"

# Apuntar a Supabase (session pooler)
$env:DATABASE_URL = "postgresql://postgres.rvgtxvzssbjnqbqonwlo:LaSinCorazon72*@aws-1-sa-east-1.pooler.supabase.com:5432/postgres"

# Crear y aplicar la migración
npx prisma migrate dev --name descripcion_del_cambio
```

Luego subir la migración al repo:

```powershell
cd "c:\Users\ventu\OneDrive\Desktop\PROYECTO GRUPAL"
git add backend-sw1-final/prisma/migrations
git commit -m "Add migration: descripcion_del_cambio"
git push origin main
```

---

## URLs de producción

| Servicio | URL |
|---|---|
| Frontend | https://nice-plant-0195a850f.7.azurestaticapps.net |
| Backend API | https://backend.gentledune-b42332e1.eastus2.azurecontainerapps.io/api |
| Backend Docs (Swagger) | https://backend.gentledune-b42332e1.eastus2.azurecontainerapps.io/api/docs |
| AI Service | https://ai-service.gentledune-b42332e1.eastus2.azurecontainerapps.io |

---

## Ver logs del backend en tiempo real

```powershell
az containerapp logs show --name backend --resource-group moda-app-rg --tail 50
```

Para ver si el contenedor está saludable:

```powershell
az containerapp revision list --name backend --resource-group moda-app-rg --output table
```

---

## Si el backend no arranca (troubleshooting)

1. Ver logs: `az containerapp logs show --name backend --resource-group moda-app-rg --tail 50`
2. Ver logs del sistema: `az containerapp logs show --name backend --resource-group moda-app-rg --type system --tail 20`
3. Verificar que el secret `db-url` tiene la URL correcta de Supabase Session Pooler (port 5432)

---

## Secrets en GitHub (Settings → Secrets → Actions)

| Secret | Para qué sirve |
|---|---|
| `AZURE_CREDENTIALS` | Login a Azure desde CI/CD |
| `ACR_LOGIN_SERVER` | Registry de Docker (modaappregistry.azurecr.io) |
| `ACR_USERNAME` | Usuario del registry |
| `ACR_PASSWORD` | Contraseña del registry |
| `DATABASE_URL` | Supabase Transaction Pooler + ?pgbouncer=true (runtime) |
| `DATABASE_MIGRATION_URL` | Supabase Session Pooler port 5432 (para migraciones en CI) |
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | Deploy del frontend |
| `VITE_API_URL` | URL del backend para el frontend |
| `VITE_AI_SERVICE_URL` | URL del AI service para el frontend |
| `VITE_STRIPE_PUBLIC_KEY` | Stripe publishable key |

---

## Base de datos (Supabase)

- **Dashboard**: https://supabase.com/dashboard/project/rvgtxvzssbjnqbqonwlo
- **Session Pooler** (migraciones): `postgresql://postgres.rvgtxvzssbjnqbqonwlo:PASSWORD@aws-1-sa-east-1.pooler.supabase.com:5432/postgres`
- **Transaction Pooler** (runtime app): `postgresql://postgres.rvgtxvzssbjnqbqonwlo:PASSWORD@aws-1-sa-east-1.pooler.supabase.com:6543/postgres?pgbouncer=true`
