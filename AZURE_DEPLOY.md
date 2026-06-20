# Despliegue en Azure — Flujo con GitHub

## Cómo funciona

```
git push → GitHub Actions → Azure Container Registry → Azure Container Apps
                         → Azure Static Web Apps (frontend, gratis)
```

Cada vez que hagas `git push` a `main`, los workflows despliegan automáticamente solo los servicios que cambiaron.

---

## Arquitectura en Azure

```
Internet
   ├── Azure Static Web Apps (GRATIS)   ← frontend-web (React)
   ├── Azure Container Apps
   │      ├── backend      (NestJS  :3000)
   │      └── ai-service   (FastAPI :8000)
   └── Azure Database for PostgreSQL     (~$13/mes)
```

**Costo estimado: ~$22-28/mes → $100 dura 3-4 meses.**

---

## PASO 1 — Instalar Azure CLI

Descarga e instala desde: https://learn.microsoft.com/cli/azure/install-azure-cli-windows

Verifica:
```bash
az --version
```

---

## PASO 2 — Crear recursos en Azure (solo una vez)

Abre PowerShell o terminal y ejecuta **en orden**:

```bash
az login
```

### Variables (cámbialas si quieres)
```bash
$RESOURCE_GROUP = "moda-app-rg"
$LOCATION       = "eastus"
$ACR_NAME       = "modaappregistry"   # Solo letras y números, único globalmente
$ENVIRONMENT    = "moda-env"
$PG_SERVER      = "moda-postgres-srv"
$PG_USER        = "appuser"
$PG_PASSWORD    = "CambiameEsto123!"  # ← pon una contraseña segura
$PG_DB          = "modadb"
```

### Grupo de recursos
```bash
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### Azure Container Registry
```bash
az acr create `
  --resource-group $RESOURCE_GROUP `
  --name $ACR_NAME `
  --sku Basic `
  --admin-enabled true
```

### PostgreSQL Flexible Server
```bash
az postgres flexible-server create `
  --resource-group $RESOURCE_GROUP `
  --name $PG_SERVER `
  --location $LOCATION `
  --admin-user $PG_USER `
  --admin-password $PG_PASSWORD `
  --sku-name Standard_B1ms `
  --tier Burstable `
  --version 16 `
  --public-access 0.0.0.0

az postgres flexible-server db create `
  --resource-group $RESOURCE_GROUP `
  --server-name $PG_SERVER `
  --database-name $PG_DB
```

Guarda la DATABASE_URL (la necesitarás después):
```
postgresql://appuser:CambiameEsto123!@moda-postgres-srv.postgres.database.azure.com:5432/modadb?sslmode=require
```

### Container Apps Environment
```bash
az extension add --name containerapp --upgrade
az provider register --namespace Microsoft.App

az containerapp env create `
  --name $ENVIRONMENT `
  --resource-group $RESOURCE_GROUP `
  --location $LOCATION
```

### Obtener credenciales del ACR
```bash
az acr credential show --name $ACR_NAME
# Anota: loginServer, username, passwords[0].value
```

---

## PASO 3 — Primer deploy manual (solo la primera vez)

GitHub Actions solo actualiza imágenes ya existentes, así que la primera vez hay que crear los Container Apps manualmente.

### Hacer el primer build y push
```bash
# Login al registry
az acr login --name $ACR_NAME

$ACR_SERVER = "modaappregistry.azurecr.io"

# Backend
docker build -t $ACR_SERVER/backend:latest ./backend-sw1-final
docker push $ACR_SERVER/backend:latest

# AI Service
docker build -t $ACR_SERVER/ai-service:latest ./python-service
docker push $ACR_SERVER/ai-service:latest
```

### Crear el Container App del Backend
```bash
az containerapp create `
  --name backend `
  --resource-group $RESOURCE_GROUP `
  --environment $ENVIRONMENT `
  --image $ACR_SERVER/backend:latest `
  --registry-server $ACR_SERVER `
  --registry-username TU_ACR_USERNAME `
  --registry-password "TU_ACR_PASSWORD" `
  --target-port 3000 `
  --ingress external `
  --min-replicas 0 `
  --max-replicas 2 `
  --cpu 0.5 `
  --memory 1.0Gi `
  --env-vars `
    PORT=3000 `
    DATABASE_URL="postgresql://appuser:PASSWORD@moda-postgres-srv.postgres.database.azure.com:5432/modadb?sslmode=require" `
    JWT_SECRET="un-secreto-muy-largo-y-seguro" `
    JWT_EXPIRES_IN=86400 `
    GEMINI_API_KEY="AIza..." `
    OPENROUTER_API_KEY="sk-or-..." `
    GROQ_API_KEY="gsk_..." `
    HF_TOKEN="hf_..." `
    CF_ACCOUNT_ID="..." `
    CF_API_TOKEN="..." `
    CLOUDINARY_CLOUD_NAME="..." `
    CLOUDINARY_API_KEY="..." `
    CLOUDINARY_API_SECRET="..." `
    STRIPE_SECRET_KEY="sk_test_..." `
    STRIPE_MONTHLY_PRICE_ID="price_..." `
    STRIPE_ANNUAL_PRICE_ID="price_..."
```

### Crear el Container App del AI Service
```bash
az containerapp create `
  --name ai-service `
  --resource-group $RESOURCE_GROUP `
  --environment $ENVIRONMENT `
  --image $ACR_SERVER/ai-service:latest `
  --registry-server $ACR_SERVER `
  --registry-username TU_ACR_USERNAME `
  --registry-password "TU_ACR_PASSWORD" `
  --target-port 8000 `
  --ingress external `
  --min-replicas 0 `
  --max-replicas 1 `
  --cpu 1.0 `
  --memory 2.0Gi
```

### Obtener las URLs de los servicios
```bash
az containerapp show --name backend      --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn -o tsv
az containerapp show --name ai-service   --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn -o tsv
```
Copia estas URLs — las necesitas para el Paso 4.

---

## PASO 4 — Crear el Static Web App y conectar GitHub

```bash
az staticwebapp create `
  --name moda-frontend `
  --resource-group $RESOURCE_GROUP `
  --source https://github.com/OLIVER2003V/MODA_ASISTENTE_IA `
  --branch main `
  --app-location "frontend-web" `
  --output-location "dist" `
  --login-with-github
```

Esto abre el browser para autorizar Azure en GitHub. Después Azure agrega automáticamente el secret `AZURE_STATIC_WEB_APPS_API_TOKEN` al repo.

---

## PASO 5 — Agregar secretos en GitHub

Ve a: `https://github.com/OLIVER2003V/MODA_ASISTENTE_IA/settings/secrets/actions`

Agrega estos **Repository secrets**:

| Secret | Valor |
|---|---|
| `AZURE_CREDENTIALS` | JSON del service principal (ver abajo) |
| `ACR_LOGIN_SERVER` | `modaappregistry.azurecr.io` |
| `ACR_USERNAME` | username del ACR |
| `ACR_PASSWORD` | password del ACR |
| `VITE_API_URL` | `https://TU-BACKEND-FQDN/api` |
| `VITE_AI_SERVICE_URL` | `https://TU-AI-SERVICE-FQDN` |

### Generar AZURE_CREDENTIALS (service principal)

```bash
az ad sp create-for-rbac `
  --name "moda-github-deploy" `
  --role contributor `
  --scopes /subscriptions/TU_SUBSCRIPTION_ID/resourceGroups/moda-app-rg `
  --sdk-auth
```

Copia el JSON completo que devuelve y pégalo como valor del secret `AZURE_CREDENTIALS`.

(Tu subscription ID: `az account show --query id -o tsv`)

---

## PASO 6 — Push y verificar

```bash
git add .
git commit -m "Add Docker and Azure deployment config"
git push origin main
```

Ve a: `https://github.com/OLIVER2003V/MODA_ASISTENTE_IA/actions`

Verás los 3 workflows corriendo. El frontend se despliega en ~2 min, el backend y AI service en ~5-8 min.

---

## Flujo desde aquí en adelante

```
Cambias código → git push origin main → GitHub Actions lo despliega solo
```

Solo se re-despliega el servicio cuyos archivos cambiaron (backend si tocaste `backend-sw1-final/`, etc.).

---

## URLs finales

- **Backend Swagger:** `https://<backend-fqdn>/api/docs`
- **AI Service docs:** `https://<ai-service-fqdn>/docs`
- **Frontend:** URL que aparece en el portal de Azure Static Web Apps

---

## Costos estimados

| Servicio | Costo/mes |
|---|---|
| Azure Database for PostgreSQL B1ms | ~$13 |
| Azure Container Registry Basic | ~$5 |
| Container Apps (escalan a 0 sin tráfico) | ~$3-7 |
| Azure Static Web Apps | GRATIS |
| **Total** | **~$21-25/mes** |

---

## Notas

- **Cold start del AI service:** con `min-replicas 0` la primera request puede tardar 3-5 min porque descarga modelos CLIP (~350 MB). Para evitarlo usa `--min-replicas 1` pero sube ~$8/mes.
- **HTTPS:** incluido automáticamente en Container Apps y Static Web Apps.
- **Logs en tiempo real:** `az containerapp logs show --name backend --resource-group moda-app-rg --follow`
