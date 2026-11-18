---
description: Revisa los cambios y crea un commit (sin push)
argument-hint: "[mensaje o pista opcional]"
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git branch:*), Bash(git tag:*), Bash(cat version.json:*)
---

## Contexto

- Rama actual: !`git branch --show-current`
- Estado: !`git status --short`
- Cambios (staged y sin stagear): !`git diff HEAD --stat`
- Últimos commits (para seguir el estilo): !`git log --oneline -10`
- Versión actual (version.json): !`cat version.json 2>/dev/null`
- Último tag de versión: !`git tag --sort=-v:refname | head -1`

## Tarea

Creá **un** commit con los cambios actuales del repo LinkStack (fork ANTARES).

1. Si la rama es `main`, avisá y no commitees. No sigas con el resto de los pasos.
2. Revisá el diff (`git diff HEAD`) para entender qué cambió.
3. No incluyas archivos que no deben versionarse: secretos, `release/`, `*.tar`, `vendor/`, `node_modules/`, bases `.sqlite` con datos reales ni archivos sueltos fuera de su carpeta (los logos van en `assets/linkstack/images/antares/`). Si aparece algo dudoso, preguntá antes.
4. Preguntá al usuario (con AskUserQuestion) qué versión le corresponde a este commit, mostrando como opciones: la versión actual sin cambios, un bump de patch sugerido (ej. si `version.json` dice `4.8.8`, sugerí `4.8.9`) y "ninguna" (este commit no amerita cambio de versión ni tag). Dejá que el usuario escriba otra versión si ninguna opción sirve.
   - Si el usuario eligió una versión distinta a la actual, actualizá `version.json` con el nuevo número (texto plano, sin prefijo `v`, terminado en salto de línea, igual formato que el archivo actual) y sumalo al commit.
   - Si eligió "ninguna", no toques `version.json` ni crees tag.
5. Agregá los archivos por nombre (`git add <rutas>`), no `git add -A`.
6. Mensaje en español, en imperativo, primera línea ≤ 72 caracteres; si hace falta, un cuerpo breve explicando el porqué. Si el usuario pasó texto, usalo como base: $ARGUMENTS
7. No hagas push. Al terminar mostrá `git log --oneline -1`.
8. Si se definió una versión nueva, creá un tag anotado `v<versión>` apuntando al commit recién creado (`git tag -a v<versión> -m "v<versión>"`), sin pushearlo. Avisá que el tag quedó solo en local.
