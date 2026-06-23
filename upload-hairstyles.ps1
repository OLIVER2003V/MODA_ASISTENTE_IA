# ─────────────────────────────────────────────────────────────
#  Subida de peinados al catálogo de ModalA
#  Uso:
#    .\upload-hairstyles.ps1 -Folder "C:\fotos\peinados" -Gender "female"
#    .\upload-hairstyles.ps1 -Folder "C:\fotos\peinados" -Gender "male"
#    .\upload-hairstyles.ps1 -Folder "C:\fotos\peinados" -Gender "unisex"
# ─────────────────────────────────────────────────────────────

param(
    [Parameter(Mandatory=$true)]
    [string]$Folder,

    [ValidateSet("male","female","unisex")]
    [string]$Gender = "unisex",

    [string]$Email    = "admin@modala.com",
    [string]$Password = "123456",

    [int]$BatchSize = 5   # imágenes por llamada (máx 20)
)

$API = "https://backend.gentledune-b42332e1.eastus2.azurecontainerapps.io/api"

# ── 1. Login ──────────────────────────────────────────────────
Write-Host "`n[1/3] Iniciando sesión..." -ForegroundColor Cyan

$loginBody = @{ email = $Email; password = $Password } | ConvertTo-Json
try {
    $auth = Invoke-RestMethod -Uri "$API/auth/login" -Method POST `
        -ContentType "application/json" -Body $loginBody
    $TOKEN = $auth.access_token
    Write-Host "      Login OK  →  $($auth.user.name)" -ForegroundColor Green
} catch {
    Write-Host "      Login fallido. Intentando registro..." -ForegroundColor Yellow
    $regBody = @{ name = "Admin ModalA"; email = $Email; password = $Password } | ConvertTo-Json
    $auth = Invoke-RestMethod -Uri "$API/auth/register" -Method POST `
        -ContentType "application/json" -Body $regBody
    $TOKEN = $auth.access_token
    Write-Host "      Registro OK  →  $($auth.user.name)" -ForegroundColor Green
}

# ── 2. Buscar imágenes ────────────────────────────────────────
Write-Host "`n[2/3] Leyendo imágenes en: $Folder" -ForegroundColor Cyan

$extensions = @("*.jpg","*.jpeg","*.png","*.webp","*.avif")
$images = @()
foreach ($ext in $extensions) {
    $images += Get-ChildItem -Path $Folder -Filter $ext -File
}

if ($images.Count -eq 0) {
    Write-Host "      No se encontraron imágenes en la carpeta." -ForegroundColor Red
    exit 1
}
Write-Host "      $($images.Count) imágenes encontradas." -ForegroundColor Green

# ── 3. Subir en lotes ─────────────────────────────────────────
Write-Host "`n[3/3] Subiendo peinados (género: $Gender)..." -ForegroundColor Cyan

$total   = 0
$errors  = 0
$batches = [math]::Ceiling($images.Count / $BatchSize)

for ($i = 0; $i -lt $batches; $i++) {
    $batch = $images | Select-Object -Skip ($i * $BatchSize) -First $BatchSize
    $names = ($batch | ForEach-Object { $_.Name }) -join ", "
    Write-Host "  Lote $($i+1)/$batches : $names" -NoNewline

    # Construir multipart form manualmente
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    $bodyParts = [System.Collections.Generic.List[byte]]::new()

    # Campo gender
    $genderPart = "--$boundary${LF}Content-Disposition: form-data; name=`"gender`"${LF}${LF}${Gender}${LF}"
    $bodyParts.AddRange([System.Text.Encoding]::UTF8.GetBytes($genderPart))

    # Archivos
    foreach ($img in $batch) {
        $mime = switch ($img.Extension.ToLower()) {
            ".jpg"  { "image/jpeg" }
            ".jpeg" { "image/jpeg" }
            ".png"  { "image/png"  }
            ".webp" { "image/webp" }
            ".avif" { "image/avif" }
            default { "image/jpeg" }
        }
        $header = "--$boundary${LF}Content-Disposition: form-data; name=`"files`"; filename=`"$($img.Name)`"${LF}Content-Type: $mime${LF}${LF}"
        $bodyParts.AddRange([System.Text.Encoding]::UTF8.GetBytes($header))
        $bodyParts.AddRange([System.IO.File]::ReadAllBytes($img.FullName))
        $bodyParts.AddRange([System.Text.Encoding]::UTF8.GetBytes($LF))
    }

    $closing = "--$boundary--${LF}"
    $bodyParts.AddRange([System.Text.Encoding]::UTF8.GetBytes($closing))

    try {
        $response = Invoke-RestMethod `
            -Uri "$API/hairstyle/upload" `
            -Method POST `
            -Headers @{ Authorization = "Bearer $TOKEN" } `
            -ContentType "multipart/form-data; boundary=$boundary" `
            -Body $bodyParts.ToArray() `
            -TimeoutSec 120

        $count = if ($response -is [array]) { $response.Count } else { 1 }
        $total += $count
        Write-Host "  ✓ $count subidos" -ForegroundColor Green
    } catch {
        $errors++
        Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ── Resumen ───────────────────────────────────────────────────
Write-Host "`n═══════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Peinados subidos : $total" -ForegroundColor Green
if ($errors -gt 0) {
    Write-Host "  Lotes con error  : $errors" -ForegroundColor Red
}
Write-Host "═══════════════════════════════════`n" -ForegroundColor Cyan
