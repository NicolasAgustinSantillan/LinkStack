#!/usr/bin/env pwsh
# release.ps1 — Construir y subir la imagen de ANTARES-LINKSTACK al registry privado

$ErrorActionPreference = "Stop"

$REGISTRY = "registry.antaresautomation.com"
$IMAGE    = "$REGISTRY/antares-linkstack"

$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

try {
Write-Host ""
Write-Host "==================================="
Write-Host "  ANTARES-LINKSTACK — Release Build"
Write-Host "==================================="
Write-Host ""

# — Version (por defecto la de version.json)
$appVersion = (Get-Content "$repoRoot\version.json" -Raw).Trim()
$versionInput = Read-Host "  Version a publicar [default: $appVersion]"
$VERSION = if ($versionInput.Trim() -eq "") { $appVersion } else { $versionInput.Trim() }
Write-Host "  Version: $VERSION"
Write-Host ""

# — Carpeta release/
if (-not (Test-Path "$repoRoot\release")) {
    New-Item -ItemType Directory "$repoRoot\release" | Out-Null
}

# — Chequeo rapido de sintaxis PHP (dentro de un contenedor, no requiere PHP local)
Write-Host "[ 1/5 ] Verificando sintaxis PHP..."
docker run --rm -v "${repoRoot}:/app" -w /app php:8.2-cli sh -c `
    "find app routes config database resources/views -name '*.php' -print0 | xargs -0 -n1 php -l > /dev/null"
if ($LASTEXITCODE -ne 0) { Write-Host "  ERROR: errores de sintaxis PHP." -ForegroundColor Red; exit 1 }

# — Docker login
Write-Host ""
Write-Host "[ 2/5 ] Login al registry..."
docker login $REGISTRY
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: No se pudo autenticar. Abortando." -ForegroundColor Red
    exit 1
}

# — Build (composer install corre dentro del Dockerfile)
Write-Host ""
Write-Host "[ 3/5 ] Construyendo imagen..."
docker build --no-cache `
    -f docker/Dockerfile `
    -t "${IMAGE}:${VERSION}" `
    .
if ($LASTEXITCODE -ne 0) { Write-Host "  ERROR: build fallido." -ForegroundColor Red; exit 1 }

# — Guardar en release/
Write-Host ""
Write-Host "[ 4/5 ] Guardando imagen en release/..."
docker save "${IMAGE}:${VERSION}" -o "release\antares-linkstack-${VERSION}.tar"
Write-Host "  release\antares-linkstack-${VERSION}.tar"

# — Control de tamaño de capas: Cloudflare (delante del registry) rechaza
#   requests de mas de 100 MB y Docker sube cada capa en un solo request
Write-Host ""
Write-Host "  Verificando tamaño comprimido de las capas (limite Cloudflare 100 MB)..."
$maxMB = 95
$tarDir = Join-Path $repoRoot "release"
$sizes = docker run --rm -v "${tarDir}:/r:ro" alpine:3.20 sh -c `
    "mkdir /x && tar -xf '/r/antares-linkstack-${VERSION}.tar' -C /x && for f in /x/blobs/sha256/*; do echo `$(gzip -c `$f | wc -c) `$(basename `$f); done"
if ($LASTEXITCODE -ne 0) { Write-Host "  ERROR: no se pudieron medir las capas." -ForegroundColor Red; exit 1 }
$big = $sizes | ForEach-Object { $p = $_ -split ' '; [pscustomobject]@{ MB = [math]::Round([double]$p[0] / 1MB, 1); Digest = $p[1].Substring(0, 12) } } |
    Sort-Object MB -Descending
Write-Host "  Capa mas grande: $($big[0].MB) MB ($($big[0].Digest))"
$tooBig = $big | Where-Object { $_.MB -gt $maxMB }
if ($tooBig) {
    $tooBig | ForEach-Object { Write-Host "  ERROR: capa $($_.Digest) pesa $($_.MB) MB comprimida." -ForegroundColor Red }
    Write-Host "  Cloudflare la rechazaria con 413. Dividir esa capa en el Dockerfile." -ForegroundColor Red
    exit 1
}

# — Push
Write-Host ""
Write-Host "[ 5/5 ] Subiendo al registry..."
docker push "${IMAGE}:${VERSION}"
if ($LASTEXITCODE -ne 0) { Write-Host "  ERROR: push fallido." -ForegroundColor Red; exit 1 }

# — Tag adicional como latest si la version no lo es
# (docker-compose.server.yml usa :latest)
if ($VERSION -ne "latest") {
    Write-Host ""
    $tagLatest = Read-Host "  Tambien taggear y pushear como 'latest'? [S/n]"
    if ($tagLatest -notmatch '^[nN]$') {
        docker tag "${IMAGE}:${VERSION}" "${IMAGE}:latest"
        docker push "${IMAGE}:latest"
        Write-Host "  Pusheado tambien como :latest"
    }
}

# — Resumen
Write-Host ""
Write-Host "==================================="
Write-Host "  Publicacion completada"
Write-Host "==================================="
Write-Host "  Imagen -> ${IMAGE}:${VERSION}"
Write-Host ""
Write-Host "  Archivo en release/:"
Write-Host "    release\antares-linkstack-${VERSION}.tar"
Write-Host ""
Write-Host "  En el servidor:"
Write-Host "    docker compose -f docker/docker-compose.server.yml pull"
Write-Host "    docker compose -f docker/docker-compose.server.yml up -d"
Write-Host ""
}
finally {
    Set-Location $PSScriptRoot
}
