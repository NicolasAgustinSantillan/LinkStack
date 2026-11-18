#!/usr/bin/env bash
# release.sh — Construir y subir la imagen de ANTARES-LINKSTACK al registry privado
set -euo pipefail

REGISTRY="registry.antaresautomation.com"
IMAGE="${REGISTRY}/antares-linkstack"
MAX_MB=95

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

push_image() {
    local ref="$1"
    local try
    for try in 1 2 3; do
        if docker push "$ref"; then
            return 0
        fi
        if [ "$try" -lt 3 ]; then
            echo "  Push fallido (intento $try/3), reintentando en 10 s..."
            sleep 10
        fi
    done
    echo "  ERROR: push fallido tras 3 intentos."
    echo "  Si se repite, limitar subidas en paralelo: Docker Desktop > Settings > Docker Engine > \"max-concurrent-uploads\": 1"
    exit 1
}

echo ""
echo "==================================="
echo "  ANTARES-LINKSTACK — Release Build"
echo "==================================="
echo ""

# — Version (por defecto la del ultimo tag de git; si no hay tags, la de version.json)
APP_VERSION="$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')"
if [ -z "$APP_VERSION" ]; then
    APP_VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/version.json")"
fi
read -r -p "  Version a publicar [default: $APP_VERSION]: " VERSION_INPUT
VERSION="${VERSION_INPUT:-$APP_VERSION}"
echo "  Version: $VERSION"
echo ""

# — Carpeta release/
mkdir -p "$REPO_ROOT/release"

# — Chequeo rapido de sintaxis PHP (dentro de un contenedor, no requiere PHP local)
echo "[ 1/5 ] Verificando sintaxis PHP..."
if ! docker run --rm -v "${REPO_ROOT}:/app" -w /app php:8.2-cli sh -c \
    "find app routes config database resources/views -name '*.php' -print0 | xargs -0 -n1 php -l > /dev/null"; then
    echo "  ERROR: errores de sintaxis PHP."
    exit 1
fi

# — Docker login
echo ""
echo "[ 2/5 ] Login al registry..."
if ! docker login "$REGISTRY"; then
    echo "  ERROR: No se pudo autenticar. Abortando."
    exit 1
fi

# — Build (composer install corre dentro del Dockerfile)
echo ""
echo "[ 3/5 ] Construyendo imagen..."
if ! docker build --no-cache \
    -f docker/Dockerfile \
    -t "${IMAGE}:${VERSION}" \
    .; then
    echo "  ERROR: build fallido."
    exit 1
fi

# — Guardar en release/
echo ""
echo "[ 4/5 ] Guardando imagen en release/..."
docker save "${IMAGE}:${VERSION}" -o "release/antares-linkstack-${VERSION}.tar"
echo "  release/antares-linkstack-${VERSION}.tar"

# — Control de tamaño de capas: Cloudflare (delante del registry) rechaza
#   requests de mas de 100 MB y Docker sube cada capa en un solo request
echo ""
echo "  Verificando tamaño comprimido de las capas (limite Cloudflare 100 MB)..."
TAR_DIR="$REPO_ROOT/release"
SIZES="$(docker run --rm -v "${TAR_DIR}:/r:ro" alpine:3.20 sh -c \
    "mkdir /x && tar -xf '/r/antares-linkstack-${VERSION}.tar' -C /x && for f in /x/blobs/sha256/*; do echo \$(gzip -c \$f | wc -c) \$(basename \$f); done")"

BIGGEST_BYTES=0
BIGGEST_DIGEST=""
TOO_BIG=0
while read -r bytes digest; do
    [ -z "$bytes" ] && continue
    if [ "$bytes" -gt "$BIGGEST_BYTES" ]; then
        BIGGEST_BYTES="$bytes"
        BIGGEST_DIGEST="$digest"
    fi
    mb=$(( bytes / 1024 / 1024 ))
    if [ "$mb" -gt "$MAX_MB" ]; then
        echo "  ERROR: capa ${digest:0:12} pesa ${mb} MB comprimida."
        TOO_BIG=1
    fi
done <<< "$SIZES"

BIGGEST_MB=$(( BIGGEST_BYTES / 1024 / 1024 ))
echo "  Capa mas grande: ${BIGGEST_MB} MB (${BIGGEST_DIGEST:0:12})"

if [ "$TOO_BIG" -eq 1 ]; then
    echo "  Cloudflare la rechazaria con 413. Dividir esa capa en el Dockerfile."
    exit 1
fi

# — Push con reintentos: el registry (detras de Cloudflare/Traefik) a veces corta
#   una subida con "blob upload invalid"; al reintentar solo sube las capas faltantes
echo ""
echo "[ 5/5 ] Subiendo al registry..."
push_image "${IMAGE}:${VERSION}"

# — Tag adicional como latest si la version no lo es
# (docker-compose.server.yml usa :latest)
if [ "$VERSION" != "latest" ]; then
    echo ""
    read -r -p "  Tambien taggear y pushear como 'latest'? [S/n]: " TAG_LATEST
    if [[ ! "$TAG_LATEST" =~ ^[nN]$ ]]; then
        docker tag "${IMAGE}:${VERSION}" "${IMAGE}:latest"
        push_image "${IMAGE}:latest"
        echo "  Pusheado tambien como :latest"
    fi
fi

# — Resumen
echo ""
echo "==================================="
echo "  Publicacion completada"
echo "==================================="
echo "  Imagen -> ${IMAGE}:${VERSION}"
echo ""
echo "  Archivo en release/:"
echo "    release/antares-linkstack-${VERSION}.tar"
echo ""
echo "  En el servidor:"
echo "    docker compose -f docker/docker-compose.server.yml pull"
echo "    docker compose -f docker/docker-compose.server.yml up -d"
echo ""
