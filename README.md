<p align="center">
  <img width="160" src="assets/linkstack/images/logo-animated.svg" alt="Antares">
</p>

<h1 align="center">Antares LinkStack</h1>

<p align="center">
  <b>Todos tus links en una sola página… y tu QR siempre a mano.</b><br>
  Fork de <a href="https://github.com/LinkStackOrg/LinkStack">LinkStack</a> personalizado por <b>Antares Automation</b>.
</p>

<p align="center">
  <img alt="Versión" src="https://img.shields.io/badge/versión-4.8.8-7ad21c?style=for-the-badge">
  <img alt="PHP" src="https://img.shields.io/badge/PHP-8.2-777BB4?style=for-the-badge&logo=php&logoColor=white">
  <img alt="Laravel" src="https://img.shields.io/badge/Laravel-9-FF2D20?style=for-the-badge&logo=laravel&logoColor=white">
  <img alt="Docker" src="https://img.shields.io/badge/Docker-listo-2496ED?style=for-the-badge&logo=docker&logoColor=white">
  <img alt="PWA" src="https://img.shields.io/badge/PWA-instalable-5A0FC8?style=for-the-badge&logo=pwa&logoColor=white">
  <img alt="Licencia" src="https://img.shields.io/badge/licencia-AGPL--3.0-blue?style=for-the-badge">
</p>

<p align="center">
  <a href="#-qué-hace">Qué hace</a> •
  <a href="#-novedades-de-este-fork">Novedades</a> •
  <a href="#-requisitos">Requisitos</a> •
  <a href="#-levantarlo-con-docker-recomendado">Docker</a> •
  <a href="#-levantarlo-sin-docker">Sin Docker</a> •
  <a href="#-publicar-una-versión">Release</a> •
  <a href="#-instalar-la-app-en-android">Android</a> •
  <a href="#-licencia-y-créditos">Licencia</a>
</p>

---

## ✨ Qué hace

**Antares LinkStack** es una plataforma autoalojada para compartir links, al estilo Linktree, pero en tu propio servidor y con tus datos.

Cada persona tiene su **página pública** (por ejemplo `https://tu-dominio.com/@Nico`) con todos sus links: redes sociales, web, WhatsApp, email, tarjeta de contacto (vCard) y más.

| | |
|---|---|
| 🔗 **Página de links personal** | Una URL única por usuario con todos sus enlaces, botones de marcas conocidas y bloques personalizables. |
| 🎨 **Temas y personalización** | Avatar, fondo, descripción, temas instalables y orden de links con arrastrar y soltar. |
| 📊 **Estadísticas** | Cantidad de clics por link y visitas a la página. |
| 👥 **Multiusuario** | Registro de usuarios, roles de administrador y panel para gestionar el sitio. |
| 📱 **QR de tu perfil** | Código QR con el isotipo de Antares, listo para mostrar y que te escaneen. |
| 🗄️ **SQLite o MySQL** | Elegís la base en el instalador web; SQLite no necesita nada extra. |

---

## 🚀 Novedades de este fork

- **📲 App instalable (PWA)** — se instala en el celular desde Chrome y se abre como una app.
- **⚡ Acceso directo "Mi QR"** — manteniendo apretado el ícono de la app aparece **Mi QR**, que se puede fijar en la pantalla de inicio. Abre el QR a pantalla completa, mantiene la pantalla encendida y **funciona sin conexión**.
- **🟢 Marca Antares** — logo propio (estático y animado) y el isotipo de Antares como marca de agua en todos los QR.
- **🐳 Docker listo para producción** — imagen Debian + PHP 8.2 + Apache, compose local y compose de servidor con **Traefik**, y script de release al registry privado.
- **🔄 Actualizaciones sin perder datos** — al desplegar una imagen nueva se actualiza el código y se conservan `.env`, base de datos e imágenes subidas.

---

## 📦 Requisitos

### Con Docker (recomendado)

| Dependencia | Versión |
|---|---|
| [Docker](https://docs.docker.com/get-docker/) | 24 o superior |
| Docker Compose | v2 (`docker compose`) |
| PowerShell 7 (`pwsh`) | solo para publicar releases |

No hace falta instalar PHP ni Composer: todo se resuelve dentro de la imagen.

### Sin Docker

| Dependencia | Versión |
|---|---|
| PHP | **8.2** (mínimo 8.0) |
| [Composer](https://getcomposer.org/) | 2.x |
| Servidor web | Apache con `mod_rewrite` (o el servidor integrado de PHP para desarrollo) |
| Base de datos | SQLite (incluida) o MySQL / MariaDB |

**Extensiones de PHP:** `bcmath`, `ctype`, `curl`, `dom`, `fileinfo`, `gd`, `intl`, `mbstring`, `openssl`, `pdo_sqlite` y/o `pdo_mysql`, `tokenizer`, `xml`, `zip`.
Recomendada: **`imagick`** — sin ella el QR se genera en SVG en lugar de PNG.

---

## 🐳 Levantarlo con Docker (recomendado)

Todo lo relacionado con Docker vive en [`./docker`](docker):

```
docker/
├── Dockerfile                  # imagen Debian + PHP 8.2 + Apache
├── docker-compose.yml          # entorno local (puerto 8080)
├── docker-compose.server.yml   # servidor con Traefik
├── entrypoint.sh               # sincroniza el código y conserva los datos
├── apache-linkstack.conf
├── php.ini
└── release.ps1                 # build + push al registry privado
```

### Local

```bash
git clone https://github.com/NicolasAgustinSantillan/LinkStack.git
cd LinkStack
git checkout ANTARES-DEV

docker compose -f docker/docker-compose.yml up -d --build
```

Abrí **http://localhost:8080** y completá el instalador web: elegís la base de datos y creás el usuario administrador.

```bash
# Ver logs
docker compose -f docker/docker-compose.yml logs -f

# Detener
docker compose -f docker/docker-compose.yml down

# Borrar también los datos (vuelve a mostrar el instalador)
docker compose -f docker/docker-compose.yml down -v
```

### Servidor (Traefik)

El compose de servidor usa la imagen del registry, se conecta a las redes externas `reverse-proxy-net` y `database-antares-net` y publica el sitio con HTTPS de Let's Encrypt.

```bash
docker compose -f docker/docker-compose.server.yml pull
docker compose -f docker/docker-compose.server.yml up -d
```

| Variable | Para qué sirve |
|---|---|
| `TZ` | Zona horaria (ej. `America/Argentina/Buenos_Aires`) |
| `HTTP_SERVER_NAME` | Dominio para Apache |
| `HTTPS_SERVER_NAME` | Dominio público |
| `FORCE_HTTPS` | `true` detrás de Traefik / HTTPS |

Los datos (configuración, base SQLite, imágenes) quedan en el volumen `linkstack_data`.

> [!TIP]
> Si el dominio pasa por **Cloudflare**, después de cambiar logos, CSS o JS conviene purgar la caché (**Caching → Purge Cache**), porque Cloudflare guarda esos archivos hasta 4 horas.

---

## 💻 Levantarlo sin Docker

```bash
git clone https://github.com/NicolasAgustinSantillan/LinkStack.git
cd LinkStack
git checkout ANTARES-DEV

composer install

# Servidor de desarrollo integrado de PHP
php -S localhost:8000 server.php
```

Abrí **http://localhost:8000** y seguí el instalador web.

**En producción con Apache**, apuntá el `DocumentRoot` a la **raíz del proyecto** (LinkStack no usa la carpeta `public/`), con `AllowOverride All` y `mod_rewrite` habilitado. El usuario del servidor web necesita permisos de escritura sobre el proyecto, sobre todo `storage/`, `database/`, `assets/img/` y `.env`.

---

## 🏷️ Publicar una versión

```powershell
pwsh docker/release.ps1
```

El script:

1. Revisa la sintaxis PHP.
2. Inicia sesión en `registry.antaresautomation.com`.
3. Construye la imagen desde cero (`--no-cache`).
4. Guarda una copia en `release/`.
5. Verifica que ninguna capa supere el límite de 100 MB de Cloudflare.
6. Sube la imagen con la versión de `version.json` y, opcionalmente, como `latest`.

Después, en el servidor: `pull` + `up -d` (ver [Servidor](#servidor-traefik)).

---

## 📱 Instalar la app en Android

1. Abrí el sitio en **Chrome** e iniciá sesión.
2. Menú **⋮** → **Instalar app**.
3. Mantené apretado el ícono de la app → arrastrá **Mi QR** a la pantalla de inicio.

¡Listo! Un toque y tu QR aparece a pantalla completa, incluso sin internet.

---

## 📜 Licencia y créditos

Este proyecto es un fork de **[LinkStack](https://github.com/LinkStackOrg/LinkStack)**, creado por [Julian Prieber](https://github.com/JulianPrieber) y la comunidad de LinkStack, que a su vez nació de [LittleLink](https://github.com/sethcottle/littlelink) de Seth Cottle.

Se distribuye bajo la licencia **[GNU AGPL v3.0](LICENSE)**: cualquier modificación desplegada debe publicarse con su código fuente y mantener los avisos de copyright y licencia.

<p align="center">
  <br>
  Hecho con 💚 por <b>Antares Automation</b>
</p>
