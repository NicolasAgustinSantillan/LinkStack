# Imagen de LinkStack (fork ANTARES) — PHP 8.2 + Apache sobre Debian 12
# Build (contexto = raíz del repo):  docker build -f docker/Dockerfile .
#
# El código se guarda en /usr/src/linkstack y el entrypoint lo sincroniza en
# /htdocs (volumen persistente). Así una imagen nueva actualiza el código sin
# pisar los datos del usuario (.env, base SQLite, imágenes subidas, etc.).
#
# El registry está detrás de Cloudflare, que rechaza requests de más de 100 MB
# (413 Payload Too Large), y Docker sube cada capa en un solo request. Por eso
# se parte de debian:bookworm-slim (trae PHP 8.2 con parches de seguridad de
# Debian) en vez de php:8.2-apache, cuya capa base comprimida pesa ~112 MB, y
# los paquetes se instalan en varias capas chicas. release.ps1 verifica el límite.

FROM debian:bookworm-slim

ENV TZ=UTC \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl rsync unzip \
      apache2 libapache2-mod-php8.2 php8.2-cli \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      php8.2-bcmath php8.2-curl php8.2-mbstring php8.2-mysql php8.2-sqlite3 \
      php8.2-xml php8.2-zip php8.2-opcache php8.2-gd \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
 && apt-get install -y --no-install-recommends php8.2-intl \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
 && apt-get install -y --no-install-recommends php8.2-imagick \
 && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite headers expires remoteip \
 && ln -sf /dev/stdout /var/log/apache2/access.log \
 && ln -sf /dev/stderr /var/log/apache2/error.log

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY docker/php.ini /etc/php/8.2/apache2/conf.d/99-linkstack.ini
COPY docker/php.ini /etc/php/8.2/cli/conf.d/99-linkstack.ini
COPY docker/apache-linkstack.conf /etc/apache2/sites-available/000-default.conf

WORKDIR /usr/src/linkstack

# Dependencias PHP primero para aprovechar la caché de capas
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --no-interaction --prefer-dist \
 && rm -rf /root/.composer/cache

COPY . .
RUN composer dump-autoload --no-dev --optimize --no-scripts \
 && rm -f bootstrap/cache/*.php \
 && sed -i 's/\r$//' .env \
 && php artisan migrate --force --no-interaction \
 && php artisan db:seed --class=PageSeeder --force --no-interaction \
 && php artisan db:seed --class=ButtonSeeder --force --no-interaction \
 && date -u +%Y%m%d%H%M%S > .image-build
# Sin "chown -R" acá: duplicaría todo el código en otra capa. El entrypoint
# ya asigna www-data a /htdocs al arrancar.

COPY docker/entrypoint.sh /usr/local/bin/linkstack-entrypoint
RUN sed -i 's/\r$//' /usr/local/bin/linkstack-entrypoint && chmod +x /usr/local/bin/linkstack-entrypoint

WORKDIR /htdocs
VOLUME /htdocs
EXPOSE 80
STOPSIGNAL SIGWINCH

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS -o /dev/null http://127.0.0.1/sw.js || exit 1

ENTRYPOINT ["linkstack-entrypoint"]
CMD ["apachectl", "-D", "FOREGROUND"]
