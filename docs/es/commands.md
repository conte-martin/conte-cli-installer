# Comandos

## Modelo mental

Conte separa la preparacion del repositorio de la gestion de hooks y el diagnostico:

- **`conte init`** — prepara el repositorio: crea `.conte/config.json`, selecciona el workflow y el mapeo de ramas, genera el commit template, e instala hooks opcionalmente.
- **`conte hooks install`** — activa las validaciones Git de forma independiente a `init`. Usar para habilitar o reparar hooks sin volver a ejecutar el asistente de configuracion completo.
- **`conte doctor`** — diagnostica el estado actual del repositorio y sugiere correcciones.

## `conte version`

Muestra solo la version instalada de Conte CLI.

Uso:

```bash
conte version
```

Diferencia importante:

- `conte version` = version instalada de la CLI
- `conte semver *` = version del proyecto en `.conte/config.json`

Los caminos viejos de version de proyecto bajo `conte version`, como `conte version current`, `conte version get`, `conte version next`, `conte version set` y `conte version breaking`, fueron eliminados. Usar `conte semver` en su lugar.

## `conte update`

Actualiza solo la CLI instalada.

Uso:

```bash
conte update
conte update --check
conte update --version 1.2.3
```

## `conte init`

Inicializa `.conte/config.json` con un asistente interactivo o con defaults no interactivos.

Uso:

```bash
conte init
conte init --yes
conte init --workflow kanban --main-branch main --force
conte init --create-missing-branches --yes
conte init --track-remote-branches --yes
```

Opciones relevantes:

- `--workflow <name>` selecciona el workflow sin pasar por el menu
- `--main-branch <name>` define el mapeo logico de `main`
- `--develop-branch <name>` define el mapeo logico de `develop`
- `--create-missing-branches` crea ramas faltantes cuando `HEAD` ya tiene commits
- `--track-remote-branches` crea ramas locales de tracking desde `origin/<branch>` cuando solo existen en remoto
- `--yes` ejecuta el flujo no interactivo
- `--force` sobrescribe `.conte/config.json`

Salida esperada tras una inicializacion exitosa:

```
Conte initialized successfully.

Repository:
  /ruta/al/repositorio

Workflow:
  kanban

Branches:
  main = main

Hooks:
  installed

Commit template:
  configured

Diagnostics:
  OK

Next:
  conte status
```

Cuando se omiten los hooks durante `init`, la salida muestra:

```
Hooks:
  not installed

  Run 'conte hooks install' to activate validations.
```

Notas:

- repositorios vacios se pueden inicializar sin primer commit
- una nueva ejecucion no interactiva simple actualiza repos inicializados legacy que todavia no tienen la seccion `hooks`
- esa misma nueva ejecucion tambien repara el estado gestionado si `hooks.enabled=true` pero faltan hooks, runtime o `core.hooksPath`
- los repos que guardan `hooks.enabled=false` de forma explicita se preservan como deshabilitados en una nueva ejecucion no interactiva
- si una rama existe solo en `origin`, el modo interactivo ofrece crear la rama local de tracking
- si la rama elegida no existe, el asistente permite reintentar, crearla, usar una rama detectada o salir sin error
- `gitflow` requiere mapeo de `develop`
- en `gitflow`, si `develop` no existe localmente y `main` existe, Conte ofrece crear `develop` desde `main`
- los hooks gestionados por Conte se instalan en `.conte/hooks`
- Git se configura con `core.hooksPath=.conte/hooks`
- Conte genera `.conte/templates/commit-template.txt` y configura `git commit.template=.conte/templates/commit-template.txt` salvo que ya exista un template local gestionado por el usuario
- la instalacion de hooks en `init` usa la misma funcion compartida que `conte hooks install`; no hay duplicacion de logica
- si esa verificacion falla, `conte init` termina con error y sugiere `conte hooks reinstall --force`

## `conte hooks`

Administra hooks Git del repositorio.

Uso:

```bash
conte hooks install
conte hooks install --force
conte hooks reinstall --force
conte hooks status
conte hooks doctor
conte hooks uninstall
conte hooks test commit-msg "fix(auth): corregir token"
conte hooks test branch feat/add-login
```

Comportamiento:

- `conte init` instala hooks por defecto; `hooks.enabled=true` queda guardado en `.conte/config.json`
- los archivos de hook viven en `.conte/hooks`, **nunca** en `.git/hooks`
- configura Git con `core.hooksPath=.conte/hooks`
- genera `.conte/templates/commit-template.txt`
- configura Git con `commit.template=.conte/templates/commit-template.txt` salvo que ya exista un template local del usuario
- guarda estado en `hooks.enabled`, `hooks.path` y `hooks.installed`
- los hooks estrategicos son `commit-msg`, `pre-push` y `prepare-commit-msg`; `pre-commit` tambien esta soportado
- cada hook gestionado por Conte incluye el marker `# Managed by Conte CLI`
- `commit-msg` valida Conventional Commits con scope obligatorio y ejecuta Hook Tasks habilitadas para `commit-msg`
- `prepare-commit-msg` carga el runtime compartido y ejecuta Hook Tasks habilitadas para `prepare-commit-msg`
- `pre-commit` y `pre-push` validan la rama actual segun las reglas del workflow y ejecutan Hook Tasks habilitadas para su hook
- `post-merge` ejecuta Hook Tasks habilitadas para `post-merge`
- en GitFlow, `pre-push` tambien valida destinos de merge del ciclo de vida cuando Git entrega refs de origen y destino
- **los hooks Git estandar no bloquean la creacion de ramas** (`git checkout -b`, `git branch`); Conte bloquea commits y pushes desde ramas invalidas

Diagnostico y reparacion:

- `conte hooks status` muestra un resumen corto de `core.hooksPath`, hooks gestionados y commit template; nunca repara
- `conte hooks doctor` muestra bloques Issue, Current, Expected, Impact y Fix; sale con codigo no cero si hay problemas
- `conte hooks test commit-msg "<mensaje>"` valida el mensaje con las mismas reglas que `commit-msg`
- `conte hooks test branch [rama]` valida la rama actual o indicada con las mismas reglas que los hooks
- los diagnosticos de hooks gestionados faltantes listan los archivos faltantes, el conjunto esperado, el `core.hooksPath` actual, el comando de reparacion y los comandos de verificacion
- los diagnosticos de hooks inactivos muestran el `core.hooksPath` actual, el valor esperado `.conte/hooks`, y explican que Git no ejecutara validaciones de commit o push
- `conte doctor --fix` muestra `Will fix:` con un resumen de cambios antes de aplicarlos, ejecuta reparaciones seguras y luego reejecutara diagnosticos con `Rerunning diagnostics.`
- `conte hooks reinstall --force` repara hooks rotos o faltantes, restaura todos los wrappers seleccionados y establece `hooks.enabled=true`; usa el conjunto de hooks por defecto cuando `installed` esta vacio

Notas:

- `conte hooks install --force` reemplaza archivos conflictivos no gestionados por Conte solo bajo `.conte/hooks`
- `conte hooks status` sale con codigo no cero cuando los hooks estan habilitados pero rotos o faltantes, y tambien cuando el repositorio esta parcialmente configurado
- en Windows, la ejecucion de hooks requiere Git Bash porque los hooks gestionados usan scripts compatibles con Bash
- `git commit --no-verify` y `git push --no-verify` saltean hooks locales
- los hooks locales pueden ser saltados; el CI/CD debe reforzar las mismas validaciones de forma remota

## `conte uninstall`

Elimina solo el estado local del repositorio gestionado por Conte en el repositorio Git actual.

Uso:

```bash
conte uninstall
conte uninstall --yes
```

Comportamiento:

- requiere estar dentro de un repositorio Git
- apunta solo a `<repo>/.conte`
- pide confirmacion por defecto
- lee `hooks.path` configurado antes de eliminar archivos gestionados
- elimina solo paths conocidos como gestionados por Conte, incluyendo `.conte/config.json`, el legacy `.conte/conte.conf`, los hooks gestionados por Conte dentro del hooks path configurado y el commit template gestionado por Conte en `.conte/templates/commit-template.txt`
- preserva archivos y directorios no gestionados dentro de `.conte`, incluyendo `.conte/templates`, `.conte/projects` y cualquier path desconocido
- elimina directorios gestionados vacios despues de limpiar archivos y elimina `.conte` solo cuando queda vacio
- limpia `core.hooksPath` local solo cuando coincide con el hooks path gestionado configurado
- limpia `commit.template` local solo cuando coincide con el path gestionado por Conte y el archivo sigue siendo gestionado por Conte
- preserva valores no relacionados de `core.hooksPath` e informa que se elimino y que se preservo
- preserva valores no relacionados o gestionados por el usuario de `commit.template` e informa que se elimino y que se preservo
- nunca elimina `~/.conte`, `%USERPROFILE%\.conte`, `.git`, archivos fuente ni la instalacion global de la CLI

Notas:

- si el repositorio actual no tiene `.conte`, Conte imprime `Conte is not initialized in this repository.` y sale con codigo 0
- si `.conte` sigue conteniendo contenido no gestionado despues de la limpieza, Conte conserva el directorio e informa las entradas restantes de nivel superior
- `conte uninstall` elimina solo la configuracion local del repositorio; no desinstala la CLI global
- para desinstalar la CLI global, usar `conte self uninstall`

## `conte self`

Administra el ciclo de vida de la CLI de Conte instalada globalmente.

Uso:

```bash
conte self version
conte self update
conte self update --version 1.2.3
conte self uninstall
conte self uninstall --yes
```

Subcomandos:

- `version` — muestra la version de la CLI (equivalente a `conte version`)
- `update` — actualiza la CLI instalada (equivalente a `conte update`)
- `uninstall` — desinstala la CLI global desde `$CONTE_HOME`

Notas:

- `conte self uninstall` elimina el directorio de instalacion global (`$CONTE_HOME`).
  No afecta la configuracion local del repositorio en `.conte`.
- Usar `conte uninstall` (dentro de un repositorio) para eliminar la configuracion local.
- `conte self uninstall` pedira confirmacion salvo que se pase `--yes`.

## `conte doctor`

Realiza diagnosticos completos y explica cada problema con un bloque estructurado:

```
Issue:
  Git core.hooksPath is not configured.

Current:
  <not set>

Expected:
  .conte/hooks

Impact:
  Git will not run Conte validations on commits or pushes.

Fix:
  conte hooks install
```

Para verificaciones saludables imprime lineas `[OK]`. Para advertencias, `[WARN]`. Para errores, el bloque estructurado Issue/Current/Expected/Impact/Fix.

`conte doctor --fix`:

- Muestra `Will fix:` con un resumen de cambios antes de aplicarlos.
- Aplica solo reparaciones seguras y deterministas.
- Muestra `Rerunning diagnostics.` y vuelve a ejecutar todos los diagnosticos.
- No sobreescribe archivos no gestionados sin `--force`.

Verifica:

- integridad de config
- presencia de `.conte/config.json`
- hooks habilitados con `core.hooksPath` faltante o desalineado
- commit template faltante, no gestionado o sin configurar
- hooks configurados faltantes
- hooks configurados sin permiso de ejecucion
- runtime roto en hooks configurados
- hooks deshabilitados como advertencia, no como falla
- disponibilidad local de la rama mapeada como `main`
- disponibilidad local de la rama mapeada como `develop` cuando el workflow la requiere
- definicion interna de ciclo de vida para GitFlow
- resolucion de ramas production y develop de GitFlow
- ramas mapeadas que existen solo en remoto
- repositorio sin commits
- detached HEAD
- validez de la rama actual
- commits recientes
- commits no-merge invalidos desde el ultimo tag para release

## `conte semver`

Administra el estado SemVer local del repositorio y los overrides manuales de release.

Uso:

```bash
conte semver get
conte semver next
conte semver set 1.2.3
conte semver breaking
```

Notas:

- `conte semver` es la UX de version del proyecto; `conte version` informa solo la version instalada de la CLI
- `conte version` muestra la version instalada de Conte CLI.
- `conte semver get` muestra la version actual del proyecto.
- `conte semver next` calcula e imprime solo la proxima version del proyecto.
- `conte semver set <version>` establece la version del proyecto.
- `conte semver breaking` marca el proximo release como MAJOR.
- despues de `conte semver breaking`, commitear `.conte/config.json` antes de ejecutar `conte release create`:

```bash
git add .conte/config.json
git commit -m "chore(release): mark next version as major"
conte release create
```

- `conte release create` consume y limpia `version.breaking` cuando el release termina bien
- los tags Git usan `vX.Y.Z` mientras la config guarda `X.Y.Z`

## `conte changelog`

Previsualiza o escribe el changelog del proximo release sin crear commits ni tags de release.

Uso:

```bash
conte changelog preview
conte changelog generate
```

## `conte release`

Genera un release desde el historial de commits.

Uso:

```bash
conte release preview
conte release create
conte release create --allow-empty-release
conte release create --scope us-12
conte release create -s us-12
conte release create --no-tag
conte release create --no-changelog
```

Notas:

- `conte release preview` muestra el plan y el changelog sin escribir archivos
- `conte release create` valida commits no-merge desde el ultimo tag
- el arbol de trabajo debe estar limpio; si `.conte/config.json` contiene un marker breaking sin commit, `conte release create` falla con instrucciones para commitearlo explicitamente
- cuando se usa `--no-tag`, el commit de release de Conte se usa como marker de release para que ejecuciones repetidas sin commits versionables nuevos no dupliquen artefactos
- los merge commits se ignoran porque la recoleccion usa `git log --no-merges`
- un Conventional Commit invalido no-merge hace fallar el release
- `--scope <scope>` filtra solo commits cuyo Conventional Commit scope coincide exactamente
- el modo scoped crea `release/<scope>` desde la branch base del workflow
- en GitFlow, `conte release create` debe ejecutarse desde la rama `develop` resuelta y rechaza production, feature, fix, bugfix, hotfix, chore y ramas release existentes
- sirve para releases por ticket, user story, issue o work item
- puede fallar si el scope seleccionado depende de commits de otros scopes
- solo `gitflow` soporta release branches scoped
- `kanban` y `trunk` no soportan release branches scoped
- los marcadores de breaking (`!` despues del scope, `BREAKING CHANGE` en el footer) no forman parte del formato v1; solo `conte semver breaking` activa un release MAJOR

Notas:

- `conte release preview` siempre es seguro; nunca escribe archivos, actualiza config ni crea tags
- los subcomandos de version bajo `conte version` (`get`, `set`, `next`, `breaking`) fueron eliminados; usar `conte semver` en su lugar
