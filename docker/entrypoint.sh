#!/bin/sh
# Sincroniza el código de la imagen en /htdocs preservando los datos del usuario
# y aplica la configuración pasada por variables de entorno.
set -e

SRC=/usr/src/linkstack
DST=/htdocs

log() { echo "[linkstack] $*"; }

# Rutas que pertenecen al usuario: nunca se sobrescriben desde la imagen
DATA_EXCLUDES="
--exclude=/.env
--exclude=/INSTALLING
--exclude=/INSTALLERLOCK
--exclude=/database/database.sqlite
--exclude=/config/advanced-config.php
--exclude=/storage/
--exclude=/assets/img/
--exclude=/.image-build
"

if [ ! -f "$DST/index.php" ]; then
    log "Volumen vacío: instalando LinkStack en $DST"
    rsync -a "$SRC/" "$DST/"
elif ! cmp -s "$SRC/.image-build" "$DST/.image-build"; then
    log "Imagen nueva detectada: actualizando código (los datos se conservan)"
    # shellcheck disable=SC2086
    rsync -a $DATA_EXCLUDES "$SRC/" "$DST/"
    # Agrega lo que falte (carpetas nuevas de storage, etc.) sin tocar lo existente
    rsync -a --ignore-existing --exclude=/INSTALLING --exclude=/.env --exclude=/database/database.sqlite "$SRC/" "$DST/"
    rm -f "$DST"/bootstrap/cache/*.php "$DST"/storage/framework/views/*.php
    cp "$SRC/.image-build" "$DST/.image-build"
    UPDATED=1
fi

# Configuración por variables de entorno (compatibles con la imagen oficial)
set_env() {
    key="$1"; value="$2"
    [ -f "$DST/.env" ] || return 0
    if grep -q "^${key}=" "$DST/.env"; then
        sed -i "s#^${key}=.*#${key}=${value}#" "$DST/.env"
    else
        printf '\n%s=%s\n' "$key" "$value" >> "$DST/.env"
    fi
}

[ -n "$FORCE_HTTPS" ] && set_env FORCE_HTTPS "$FORCE_HTTPS"
[ -n "$APP_URL" ] && set_env APP_URL "$APP_URL"
# El updater integrado descargaría la versión oficial y pisaría este fork
set_env NOTIFY_UPDATES false

if [ -n "$HTTP_SERVER_NAME" ]; then
    sed -i "s#^ServerName .*#ServerName ${HTTP_SERVER_NAME}#" /etc/apache2/sites-available/000-default.conf
fi

chown -R www-data:www-data "$DST"

# Clave de la app (sin ella Laravel no puede cifrar la sesión del instalador)
if [ -f "$DST/.env" ] && grep -Eq '^APP_KEY=[[:space:]]*$' "$DST/.env"; then
    log "Generando APP_KEY"
    su -s /bin/sh www-data -c "cd $DST && php artisan key:generate --force" >/dev/null
fi

# Migraciones pendientes tras una actualización (solo si ya está instalado)
if [ "${UPDATED:-0}" = "1" ] && [ ! -f "$DST/INSTALLING" ]; then
    log "Ejecutando migraciones"
    su -s /bin/sh www-data -c "cd $DST && php artisan migrate --force" || log "Aviso: migrate falló, revisar logs"
fi

exec "$@"
