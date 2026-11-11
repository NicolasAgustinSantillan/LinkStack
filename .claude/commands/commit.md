---
description: Revisa los cambios y crea un commit (sin push)
argument-hint: "[mensaje o pista opcional]"
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git branch:*)
---

## Contexto

- Rama actual: !`git branch --show-current`
- Estado: !`git status --short`
- Cambios (staged y sin stagear): !`git diff HEAD --stat`
- Últimos commits (para seguir el estilo): !`git log --oneline -10`

## Tarea

Creá **un** commit con los cambios actuales del repo LinkStack (fork ANTARES).

1. Revisá el diff (`git diff HEAD`) para entender qué cambió.
2. No incluyas archivos que no deben versionarse: secretos, `release/`, `*.tar`, `vendor/`, `node_modules/`, bases `.sqlite` con datos reales ni archivos sueltos fuera de su carpeta (los logos van en `assets/linkstack/images/antares/`). Si aparece algo dudoso, preguntá antes.
3. Agregá los archivos por nombre (`git add <rutas>`), no `git add -A`.
4. Mensaje en español, en imperativo, primera línea ≤ 72 caracteres; si hace falta, un cuerpo breve explicando el porqué. Si el usuario pasó texto, usalo como base: $ARGUMENTS
5. Si la rama es `main`, avisá y no commitees.
6. No hagas push. Al terminar mostrá `git log --oneline -1`.
