-- Borrar usuarios cargados por error (MySQL)
-- Ejecutar como script completo (DBeaver: Alt+X).

-- 0) Rango de IDs a borrar: cambiarlo SOLO acá
SET @desde = 963506;
SET @hasta = 963530;

-- 1) Revisar qué se va a borrar
SELECT u.id, u.name, u.email, u.littlelink_name, u.role,
       (SELECT COUNT(*) FROM linkstack_qa.links l WHERE l.user_id = u.id) AS links
FROM linkstack_qa.users u
WHERE u.id BETWEEN @desde AND @hasta
ORDER BY u.id;

-- 2) Borrar primero los links (FK links_user_id_foreign) y después los usuarios.
--    "role = 'user'" evita borrar un admin aunque el rango esté mal.
START TRANSACTION;

DELETE l FROM linkstack_qa.links l
JOIN linkstack_qa.users u ON u.id = l.user_id
WHERE u.id BETWEEN @desde AND @hasta
  AND u.role = 'user';

DELETE FROM linkstack_qa.users
WHERE id BETWEEN @desde AND @hasta
  AND role = 'user';

COMMIT;

-- 3) Comprobación: tiene que dar 0
SELECT COUNT(*) AS quedan FROM linkstack_qa.users WHERE id BETWEEN @desde AND @hasta AND role = 'user';
