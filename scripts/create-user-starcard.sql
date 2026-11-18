-- Crea el usuario 'starcard' con todos los permisos sobre la base antares_apps_starcard.
-- Ejecutar conectado como un usuario con privilegios (root o admin) en el servidor MySQL.

CREATE USER IF NOT EXISTS 'starcard'@'%' IDENTIFIED BY 'sr3NCbXM544jIsDJjb7S';

GRANT ALL PRIVILEGES ON antares_apps_starcard.* TO 'starcard'@'%';

FLUSH PRIVILEGES;
