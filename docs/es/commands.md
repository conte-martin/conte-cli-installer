# Comandos

## Modelo mental

Conte separa la preparacion del repositorio de la gestion de hooks y el diagnostico:

- **`conte init`** prepara el repositorio: crea `.conte/config.json`, selecciona el workflow y el mapeo de ramas, genera el commit template e instala hooks opcionalmente.
- **`conte hooks install`** activa las validaciones Git de forma independiente a `init`.
- **`conte doctor`** diagnostica el estado actual del repositorio y sugiere correcciones.

Regla interactiva: los comandos complejos sin argumentos pueden abrir menus solo en terminales interactivas. En CI o modo no interactivo no se muestran menus.

Comandos que pueden abrir menus en modo interactivo sin argumentos:

- `conte init`: asistente completo de onboarding.
- `conte hooks`: menu de gestion de hooks.
- `conte config`: menu de configuracion.
- `conte release`: menu de release.

Comandos siempre directos:

- `conte status`, `conte doctor`, `conte version`, `conte update`, `conte uninstall`, `conte self`.

## `conte help`

Muestra ayuda global o ayuda especifica de un comando.

Uso:

```bash
conte help
conte help semver
conte --help
conte -h
conte --version
conte -v
```

Notas:

- `conte help`, `conte --help` y `conte -h` imprimen la ayuda global agrupada.
- `conte help <command>` delega a la ayuda del comando para comandos top-level implementados.
- Los temas de ayuda desconocidos vuelven a mostrar la ayuda global.
- `conte --version` y `conte -v` imprimen la version instalada de la CLI.
- No modifican el repositorio ni la instalacion y son aptos para scripts.

## `conte version`

Muestra solo la version instalada de Conte CLI.

Uso:

```bash
conte version
conte version show
```

Notas:

- `conte version` = version instalada de la CLI.
- `conte semver *` = version del proyecto en `.conte/config.json`.
- `show` es un alias explicito aceptado por el parser.
- No modifica archivos y es apto para scripts.
- Las rutas antiguas de version de proyecto bajo `conte version`, como `conte version current`, `conte version get`, `conte version next`, `conte version set` y `conte version breaking`, no estan soportadas. Usar `conte semver`.

## `conte update`

Actualiza solo la CLI instalada.

Uso:

```bash
conte update
conte update --check
conte update --version 1.2.3
```

Opciones:

- `--check`: consulta metadata y reporta si hay actualizacion disponible sin instalar.
- `--version <x.y.z>`: solicita una version especifica.
- `-h`, `--help`: muestra ayuda.

`--check` no modifica archivos. `conte update` y `conte update --version` pueden modificar la instalacion de la CLI.

## `conte init`

Inicializa `.conte/config.json` con un asistente interactivo o con defaults no interactivos.

Uso:

```bash
conte init
conte init --yes
conte init --workflow kanban --main-branch main --force
conte init --workflow trunk --yes
conte init --workflow gitflow --main-branch main --develop-branch develop --yes
conte init --advanced
conte init --create-missing-branches --yes
conte init --track-remote-branches --yes
conte init --no-hooks --yes
```

Opciones:

- `-f`, `--force`: sobrescribe una `.conte/config.json` existente sin preguntar.
- `-y`, `--yes`: ejecuta con defaults no interactivos.
- `-w`, `--workflow <name>`: selecciona workflow. Valores soportados: `trunk`, `gitflow`, `kanban`.
- `--main-branch <name>`: define el mapeo logico de `main`.
- `--develop-branch <name>`: define el mapeo logico de `develop` para `gitflow`.
- `--create-missing-branches`: crea ramas mapeadas faltantes cuando `HEAD` ya tiene commits.
- `--track-remote-branches`: crea ramas locales de tracking desde `origin/<branch>`.
- `--advanced`: aceptado por compatibilidad; actualmente no cambia el comportamiento del parser.
- `--no-hooks`: omite la instalacion de hooks.
- `-h`, `--help`: muestra ayuda.

Comportamiento:

- Sin argumentos en una terminal interactiva, abre el asistente.
- En modo no interactivo con `--yes`, usa defaults.
- Es mutante: puede escribir `.conte/config.json`, `.conte/templates/commit-template.txt`, hooks en `.conte/hooks`, y configuracion Git local.
- Si hooks quedan habilitados, Git se configura con `core.hooksPath=.conte/hooks`.
- El commit template gestionado se escribe en `.conte/templates/commit-template.txt` y se activa con `git config commit.template .conte/templates/commit-template.txt`, salvo que ya exista un template local no gestionado.
- Una configuracion Conte nueva inicia la version del proyecto en `0.1.0`; reconfigure, `--force`, reparacion de hooks, `doctor --fix` y `hooks reinstall` preservan la version existente.
- La version del proyecto es estado de release y solo cambia con `conte semver set-version` / `conte semver set` o comandos de release.
- Los workflows soportados por la configuracion actual son `trunk`, `gitflow` y `kanban`. `github-flow` y `release-flow` son nombres legacy detectables, pero no son workflows validos para nueva configuracion.
- En Windows, la ejecucion posterior de hooks requiere Git Bash.

## `conte config`

Lee o actualiza configuracion Conte.

Uso:

```bash
conte config
conte config list
conte config --local
conte config --global
conte config get workflow
conte config get git.mainBranch
conte config get git.mapping.main
conte config set version.current 1.2.3
```

Claves de lectura:

`workflow`, `version.current`, `version.breaking`, `git.mainBranch`, `git.developBranch`, `git.mapping.main`, `git.mapping.develop`, `commit.scopeRequired`, `commit.scopePattern`, `release.command`, `release.tagPrefix`, `release.changelogFile`, `breakingChange.mode`, `breakingChange.nextBump`, `hooks.enabled`, `hooks.path`, `hooks.installed`, `hooks.tasks`.

Claves de escritura:

`workflow`, `version.current`, `version.breaking`, `git.mainBranch`, `git.developBranch`, `git.mapping.main`, `git.mapping.develop`, `commit.scopeRequired`, `commit.scopePattern`, `release.command`, `release.tagPrefix`, `release.changelogFile`, `hooks.enabled`, `hooks.path`.

Notas:

- Sin argumentos en una terminal interactiva, abre un menu.
- Sin argumentos en CI o modo no interactivo, imprime la configuracion efectiva.
- `get` no modifica archivos.
- `set` modifica la configuracion local del repositorio.
- Gestionar `hooks.installed` y `hooks.tasks` con comandos `conte hooks`.

## `conte uninstall`

Elimina solo el estado local del repositorio gestionado por Conte.

Uso:

```bash
conte uninstall
conte uninstall --yes
conte uninstall -y
```

Opciones:

- `-y`, `--yes`: elimina sin confirmacion interactiva.
- `-h`, `--help`: muestra ayuda.

Comportamiento:

- Es mutante y requiere estar dentro de un repositorio Git.
- Elimina solo paths gestionados por Conte bajo `<repo>/.conte`.
- Preserva archivos no gestionados, `.git`, archivos fuente y la instalacion global.
- Limpia `core.hooksPath` y `commit.template` solo cuando siguen apuntando a paths gestionados por Conte.
- Para desinstalar la CLI global, usar `conte self uninstall`.

## `conte semver`

Administra la version SemVer local del repositorio y overrides manuales de release.

Uso:

```bash
conte semver get-version
conte semver get
conte semver set-version 1.2.3
conte semver set 1.2.3
conte semver next-version
conte semver next
conte semver breaking
```

Aliases:

- `get-version -> get`
- `set-version -> set`
- `next-version -> next`

Notas:

- `conte version` muestra la version instalada de la CLI.
- `conte semver *` gestiona la version del proyecto en `.conte/config.json`.
- `get` y `next` no modifican archivos.
- `set` modifica `version.current`.
- `breaking` marca el proximo release como MAJOR y no cambia inmediatamente `version.current`.
- Despues de `conte semver breaking`, commitear `.conte/config.json` antes de `conte release create`.

## `conte generate cicd`

Genera templates CI/CD para enforcement remoto.

Uso:

```bash
conte generate cicd
conte generate cicd github
conte generate cicd gitlab
conte generate cicd azure
conte generate cicd --provider github
conte generate cicd --provider gitlab
conte generate cicd --provider azure
```

Providers aceptados:

- `github`
- `gitlab`
- `azure`

Es mutante: escribe el template CI/CD correspondiente al provider. Los templates llaman a Conte en vez de reimplementar reglas.
Si no se indica provider, una terminal interactiva pregunta cual usar; en modo no interactivo el fallback es `github`.

## `conte status`

Muestra un resumen breve del estado del repositorio.

Uso:

```bash
conte status
```

Notas:

- No modifica archivos y es apto para chequeos rapidos.
- Muestra inicializacion, workflow, rama principal, rama actual, hooks, scope de commit, modo breaking y proximo bump.
- Para diagnosticos detallados, usar `conte doctor`.

## `conte doctor`

Ejecuta diagnosticos completos del repositorio.

Uso:

```bash
conte doctor
conte doctor --fix
```

Opciones:

- `--fix`: aplica reparaciones seguras y deterministas.
- `-h`, `--help`: muestra ayuda.

Notas:

- `conte doctor` no modifica archivos.
- `conte doctor --fix` puede reinstalar hooks gestionados, configurar `core.hooksPath=.conte/hooks` y reinstalar el commit template gestionado.
- No sobreescribe archivos no gestionados sin una ruta de reparacion explicita.

## `conte validate`

Ejecuta validaciones explicitas sin pasar por hooks Git.

Uso:

```bash
conte validate commit "fix(auth): corregir token"
conte validate commit --file .git/COMMIT_EDITMSG
conte validate branch
conte validate branch feat/add-login
conte validate repo
```

Notas:

- `commit <message>` valida un mensaje Conventional Commit con scope obligatorio.
- `commit --file <path>` valida un mensaje leido desde archivo.
- `branch` valida la rama actual.
- `branch <name>` valida una rama indicada sin hacer checkout.
- `repo` valida configuracion, workflow, mapeo de ramas y consistencia de hooks.
- No modifica archivos y es apto para CI.

## `conte workflow`

Valida reglas explicitas de workflow.

Uso:

```bash
conte workflow validate-merge --source feature/login --target develop
conte workflow validate-merge -s feature/login -t develop
```

Notas:

- `validate-merge` requiere `--source` y `--target`.
- `-s` y `-t` son aliases cortos.
- No modifica archivos.

## `conte hooks`

Administra hooks Git del repositorio.

Uso:

```bash
conte hooks
conte hooks status
conte hooks install
conte hooks install --force
conte hooks reinstall --force
conte hooks uninstall
conte hooks doctor
conte hooks test commit-msg "fix(auth): corregir token"
conte hooks test branch feat/add-login
conte hooks task
conte hooks task list
conte hooks task --help
conte hooks task add dotnet-test --hook pre-push -- dotnet test
conte hooks task edit dotnet-test --name dotnet-test-all --hook manual --enable -- dotnet test
conte hooks task remove dotnet-test
conte hooks task enable dotnet-test
conte hooks task disable dotnet-test
conte hooks task run dotnet-test
conte hooks task menu
```

Comportamiento:

- Sin subcomando en terminal interactiva, abre un menu.
- Sin subcomando en modo no interactivo, ejecuta `conte hooks status`.
- `status`, `doctor` y `test` no modifican archivos.
- `install`, `reinstall` y `uninstall` modifican hooks gestionados y configuracion local.
- Los hooks viven bajo `.conte/hooks`, no bajo `.git/hooks`.
- Los hooks gestionados incluyen `commit-msg`, `prepare-commit-msg`, `pre-commit`, `pre-push` y, cuando hay tareas, `post-merge`.
- `conte hooks test commit-msg "<message>"` valida con las mismas reglas que el hook `commit-msg`.
- `conte hooks test branch [branch-name]` valida la rama actual o indicada con las mismas reglas usadas por los hooks.
- `pre-commit` bloquea commits directos en ramas protegidas antes de ejecutar Hook Tasks.
- `commit-msg` tambien bloquea commits directos en ramas protegidas despues de validar el mensaje, como proteccion de respaldo.
- Las ramas protegidas son la rama main resuelta, `main`, `master`, la rama develop resuelta y `develop`; los nombres duplicados se muestran una sola vez.
- Automatizacion de CI o release puede habilitar explicitamente `CONTE_ALLOW_PROTECTED_BRANCH_COMMIT=true`; este override es solo para automatizacion.
- En Windows, la ejecucion de hooks requiere Git Bash.
- Los hooks locales pueden saltearse con `git commit --no-verify` o `git push --no-verify`; branch protection del repositorio y CI/CD siguen siendo requeridos.

## `conte hooks task`

Administra Hook Tasks locales del repositorio.

Uso:

```bash
conte hooks task
conte hooks task list
conte hooks task add dotnet-test --hook pre-push -- dotnet test
conte hooks task add slow-check --hook manual --disabled -- ./check.sh
conte hooks task edit dotnet-test --name dotnet-test-all --hook manual --enable -- dotnet test
conte hooks task remove dotnet-test
conte hooks task enable dotnet-test
conte hooks task disable dotnet-test
conte hooks task run dotnet-test
conte hooks task menu
```

Sintaxis:

- `conte hooks task add <name> --hook <hook|manual> [--disabled] -- <command>`
- `conte hooks task edit <name> [--name <new-name>] [--hook <hook|manual>] [--enable|--disable] [-- <command>]`

Targets soportados:

- `commit-msg`
- `prepare-commit-msg`
- `pre-commit`
- `pre-push`
- `post-merge`
- `manual`

Notas:

- `list` no modifica archivos.
- `add`, `edit`, `remove`, `enable` y `disable` modifican `hooks.tasks`.
- `run` ejecuta la tarea indicada.
- Agregar una tarea asociada a un hook Git agrega ese hook a `hooks.installed`; si los hooks estan habilitados, Conte escribe el wrapper gestionado.
- Hook Tasks no registran comandos Conte ni reemplazan la validacion interna.

## `conte self`

Administra el ciclo de vida de la CLI instalada.

Uso:

```bash
conte self version
conte self update
conte self update --check
conte self update --version 1.2.3
conte self uninstall
conte self uninstall -y
conte self uninstall --yes
```

Subcomandos:

- `version`: equivalente a `conte version`.
- `update`: delega a `conte update` y acepta `--check` y `--version <x.y.z>`.
- `uninstall`: elimina la instalacion global desde `$CONTE_HOME`.

`self version` y `self update --check` no modifican archivos. `self update` y `self uninstall` pueden modificar la instalacion global. `self uninstall` no afecta la configuracion local del repositorio.

## `conte changelog`

Previsualiza o escribe el changelog del proximo release.

Uso:

```bash
conte changelog preview
conte changelog generate
```

Notas:

- `preview` imprime el contenido del proximo changelog y no escribe archivos.
- `generate` escribe contenido de changelog solamente.
- La creacion de releases sigue bajo `conte release create`.
- La fuente de verdad del changelog son Conventional Commits; merge commits y titulos de PR no son fuentes de changelog.

## `conte release`

Genera releases desde Conventional Commits.

Uso:

```bash
conte release preview
conte release preview --allow-empty-release
conte release preview --scope us-12
conte release preview -s us-12
conte release preview --scope-mode strict
conte release preview -m strict
conte release preview --include-internal
conte release preview --no-tag
conte release preview --no-changelog
conte release create
conte release create --allow-empty-release
conte release create --scope us-12
conte release create -s us-12
conte release create --scope us-12 --scope-mode strict
conte release create -s us-12 -m strict
conte release create --include-internal
conte release create --no-tag
conte release create --no-changelog
conte release sync-develop
conte release sync-develop --preview
```

Opciones de `preview` y `create`:

- `--allow-empty-release`: permite release sin commits versionables.
- `--scope`, `-s <scope>`: limita el release a commits con ese scope exacto.
- `--scope-mode`, `-m <full|strict>`: controla el modo scoped.
- `--include-internal`: incluye commits internos con scope `release` en el changelog.
- `--no-tag`: crea release sin tag Git.
- `--no-changelog`: crea release sin escribir `CHANGELOG.md`.

Notas:

- `conte release preview` es un dry-run seguro y no escribe archivos.
- `conte release create` es mutante: actualiza config/changelog y crea tag salvo opciones que lo omitan.
- `conte release sync-develop [--preview]` esta disponible solo para GitFlow segun el codigo.
- Los commits son la fuente de verdad.
- Merge commits y titulos de PR no son fuentes de changelog.
- `git log --no-merges` es la base de recoleccion de commits para release.
- `feat(scope): ...` produce bump minor; `fix(scope): ...` y `perf(scope): ...` producen bump patch.
- El scope de commit es obligatorio.
- Breaking releases se activan manualmente con `conte semver breaking`.
- `!` y `BREAKING CHANGE` son sintaxis aceptada, pero MAJOR requiere el marcador manual de `conte semver breaking`.
- `--scope <scope>` filtra por coincidencia exacta del scope Conventional Commit.
- `--scope-mode full|strict` controla la base del branch scoped; `-m` es el alias corto.
- Scoped release branches son soportadas por `gitflow`; `kanban` y `trunk` no las soportan.
