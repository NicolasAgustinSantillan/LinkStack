-- Carga masiva de usuarios + links de una plantilla (MySQL 8.0+)
-- Contraseña inicial de todos: Antares2026! (pedirles que la cambien)
--
-- Ejecutar como script completo (DBeaver: Alt+X). Se puede correr más de una vez:
-- saltea emails/usuarios existentes y no duplica links.
-- scripts/carga-masiva.ps1 genera una copia de este archivo con los usuarios de un Excel.

START TRANSACTION;

-- 0) Plantilla con los links por defecto (Admin → Plantillas de usuarios)
SET @plantilla = 'Antares';

-- 1) Usuarios a cargar: nombre, email, usuario (/@usuario) y nombre de la plantilla
DROP TEMPORARY TABLE IF EXISTS carga;
CREATE TEMPORARY TABLE carga (
  name VARCHAR(255),
  email VARCHAR(255),
  littlelink_name VARCHAR(255),
  template VARCHAR(255)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;   -- misma collation que las tablas de Laravel

INSERT INTO carga (name, email, littlelink_name, template) VALUES
  ('Juan Pérez',   'jperez@antaresautomation.com',   'jperez',   @plantilla),
  ('María Gómez',  'mgomez@antaresautomation.com',   'mgomez',   @plantilla),
  ('Carlos Ruiz',  'cruiz@antaresautomation.com',    'cruiz',    @plantilla);

-- 2) Crear los usuarios (saltea emails o usuarios que ya existen)
INSERT INTO users (name, email, email_verified_at, password, littlelink_name, role, block, theme, created_at, updated_at)
SELECT c.name,
       LOWER(c.email),
       NOW(),
       '$2y$10$U02IXjSfGugNKdvQoKo0Fu23c0ZnqYHx/9cKsF3ELYSScRFX0UWc.',  -- Antares2026!
       LOWER(c.littlelink_name),
       'user', 'no', 'default',
       NOW(), NOW()
FROM carga c
WHERE LOWER(c.email) NOT IN (SELECT LOWER(email) FROM users)
  AND LOWER(c.littlelink_name) NOT IN (SELECT LOWER(littlelink_name) FROM users WHERE littlelink_name IS NOT NULL);

-- 3) Copiar los links de la plantilla a cada usuario que todavía no tiene links
INSERT INTO links (user_id, button_id, link, title, type, type_params, `order`, click_number, up_link, custom_css, custom_icon, created_at, updated_at)
SELECT u.id,
       CASE jt.item_type
         WHEN 'heading'    THEN 42
         WHEN 'predefined' THEN b.id
         WHEN 'email'      THEN 6                                   -- botón "default email"
         ELSE CASE WHEN jt.site_icon = 'true' OR jt.site_icon = '1' THEN 2 ELSE 1 END
       END,
       CASE WHEN jt.item_type = 'email' THEN CONCAT('mailto:', u.email) ELSE COALESCE(jt.url, '') END,
       COALESCE(NULLIF(jt.title, ''), CASE WHEN jt.item_type = 'email' THEN u.email END, b.alt, ''),
       jt.item_type,
       CASE jt.item_type
         WHEN 'heading' THEN '{"custom_html":true,"ignore_container":false,"include_libraries":[]}'
         ELSE '{"custom_html":false,"ignore_container":false,"include_libraries":[]}'
       END,
       jt.ord,
       0, 'no', '', 'fa-external-link',
       NOW(), NOW()
FROM carga c
JOIN users u          ON LOWER(u.email) = LOWER(c.email)
JOIN user_templates t ON t.name = c.template
JOIN JSON_TABLE(
       t.items,
       '$[*]' COLUMNS (
         ord       FOR ORDINALITY,
         item_type VARCHAR(50)  PATH '$.type',
         button    VARCHAR(100) PATH '$.button',
         url       TEXT         PATH '$.url',
         title     VARCHAR(255) PATH '$.title',
         site_icon VARCHAR(10)  PATH '$.site_icon'
       )
     ) AS jt
LEFT JOIN buttons b   ON b.name = jt.button COLLATE utf8mb4_unicode_ci   -- JSON_TABLE usa otra collation
WHERE NOT EXISTS (SELECT 1 FROM links l WHERE l.user_id = u.id)
  AND (jt.item_type <> 'predefined' OR b.id IS NOT NULL);

-- 4) Resultado: user_id vacío = no se creó (el /@usuario ya lo usa otra cuenta)
SELECT c.name, c.email, c.littlelink_name, u.id AS user_id,
       (SELECT COUNT(*) FROM links l WHERE l.user_id = u.id) AS links
FROM carga c
LEFT JOIN users u ON LOWER(u.email) = LOWER(c.email);

DROP TEMPORARY TABLE IF EXISTS carga;

COMMIT;
