# Comandos

## Modelo mental

Conte separa la preparacion del repositorio de la gestion de hooks y el diagnostico:

- **`conte init`** prepara el repositorio: crea `.conte/config.json`, selecciona el workflow y el mapeo de ramas, genera el commit template e instala hooks opcionalmente.
- **`conte history adopt`** registra el baseline de adopcion para repositorios con historial previo a Conte.
- **`conte hooks install`** activa las validaciones Git de forma independiente a `init`.
- **`conte doctor`** diagnostica la preparacion de la CLI/runtime y del repositorio, y sugiere correcciones locales seguras.

Regla interactiva: los comandos complejos sin argumentos pueden abrir menus solo en terminales interactivas. En CI o modo no interactivo no se muestran menus.

Comandos que pueden abrir menus en modo interactivo sin argumentos:

- `conte init`: asistente completo de onboarding.
- `conte menu`: menu principal de comandos.
- `conte hooks`: menu de gestion de hooks.
- `conte config`: menu de configuracion.
- `conte release`: menu de release.

Comandos siempre directos:

- `conte status`, `conte doctor`, `conte version`, `conte update`, `conte uninstall`, `conte remove`, `conte self`.

Los menus solo aparecen si stdin y stdout son TTY y no se detecta CI. `--yes` y `--no-interactive` tambien desactivan menus y prompts. Los flujos interactivos siempre tienen equivalentes explicitos como `conte init --yes`, `conte doctor --fix`, `conte release preview` y `conte release create --yes`.

La ayuda global agrupa comandos por intencion: Getting started, Daily workflow, Release, Workspace, Configuration y System.

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

## Aliases cortos de opciones

Las opciones largas son la ruta canonica de implementacion. Las opciones cortas publicas se normalizan a su opcion larga antes de que corra la logica especifica del comando.

| Opcion larga | Opcion corta |
| --- | --- |
| `--help` | `-h` |
| `--version` | `-v` |
| `--yes` | `-y` |
| `--force` | `-f` |
| `--quiet` | `-q` |
| `--verbose` | `-V` |
| `--output` | `-o` |
| `--config` | `-c` |
| `--global` | `-g` |
| `--local` | `-l` |
| `--scope` | `-s` |
| `--workflow` | `-w` |
| `--service` | `-S` |
| `--main-branch` | `-m` |
| `--dry-run` | `-n` |

Cuando una opcion corta seria ambigua dentro de un comando, Conte usa el significado local mostrado en la ayuda. Por ejemplo, `workflow validate-merge -s` significa `--source`, mientras que `release -s` significa `--scope`.

## Color y avisos de actualizacion

El color esta centralizado y por defecto solo se emite en TTY. Usar `CONTE_COLOR=auto|always|never`, `NO_COLOR=1` o `FORCE_COLOR=1` para controlar ANSI. No se emiten codigos ANSI por defecto cuando la salida esta redirigida o se detecta CI.

`conte`, `conte help`, `conte version`, `conte status` y `conte doctor` pueden mostrar un aviso cacheado de actualizacion. El cache vive en `CONTE_HOME/cache`, se refresca como maximo cada 24 horas y nunca hace fallar el comando original. Se desactiva con `CONTE_UPDATE_CHECK=0` o `conte config set update.check false`. `conte update` sigue siendo el flujo explicito de instalacion.

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
conte update -c
conte update -v 1.2.3
```

Opciones:

- `-c`, `--check`: consulta metadata y reporta si hay actualizacion disponible sin instalar.
- `-v`, `--version <x.y.z>`: solicita una version especifica.
- `-h`, `--help`: muestra ayuda.

`--check` no modifica archivos. `conte update` y `conte update --version` pueden modificar la instalacion de la CLI.

## `conte init`

Inicializa `.conte/config.json` con un asistente interactivo o con defaults no interactivos.

Uso:

```bash
conte init
conte init -y
conte init -w kanban -M main -f
conte init -w trunk -y
conte init -w gitflow -M main -d develop -y
conte init --advanced
conte init -C -y
conte init -T -y
conte init -N -y
conte init --interactive
```

Opciones:

- `-f`, `--force`: sobrescribe una `.conte/config.json` existente sin preguntar.
- `-y`, `--yes`: ejecuta con defaults no interactivos.
- `--interactive`: prefiere el asistente cuando hay TTY disponible.
- `--no-interactive`: desactiva prompts incluso cuando hay TTY.
- `-w`, `--workflow <name>`: selecciona workflow. Valores soportados: `trunk`, `gitflow`, `kanban`.
- `-M`, `--main-branch <name>`: define el mapeo logico de `main`.
- `-d`, `--develop-branch <name>`: define el mapeo logico de `develop` para `gitflow`.
- `-C`, `--create-missing-branches`: crea ramas mapeadas faltantes cuando `HEAD` ya tiene commits.
- `-T`, `--track-remote-branches`: crea ramas locales de tracking desde `origin/<branch>`.
- `-a`, `--advanced`: aceptado por compatibilidad; actualmente no cambia el comportamiento del parser.
- `-N`, `--no-hooks`: omite la instalacion de hooks.
- `-h`, `--help`: muestra ayuda.

Comportamiento:

- Sin argumentos en una terminal interactiva, abre el asistente.
- En modo no interactivo con `--yes`, usa defaults.
- En repositorios existentes con `HEAD`, `conte init --yes` guarda `release.baselineRef=HEAD`; el modo interactivo pregunta si se empieza a trackear releases desde el `HEAD` actual.
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
conte config -l
conte config -g
conte config get workflow
conte config get git.mainBranch
conte config get git.mapping.main
conte config set version.current 1.2.3
```

Claves de lectura:

`workflow`, `version.current`, `version.breaking`, `git.mainBranch`, `git.developBranch`, `git.mapping.main`, `git.mapping.develop`, `commit.scopeRequired`, `commit.scopePattern`, `release.command`, `release.tagPrefix`, `release.changelogFile`, `release.baselineRef`, `release.baselineVersion`, `release.historyPolicy`, `release.invalidCommitPolicy`, `breakingChange.mode`, `breakingChange.nextBump`, `hooks.enabled`, `hooks.path`, `hooks.installed`, `hooks.tasks`, `workspace.enabled`, `workspace.releaseMode`, `update.check`.

Claves de escritura:

`workflow`, `version.current`, `version.breaking`, `git.mainBranch`, `git.developBranch`, `git.mapping.main`, `git.mapping.develop`, `commit.scopeRequired`, `commit.scopePattern`, `release.command`, `release.tagPrefix`, `release.changelogFile`, `release.baselineRef`, `release.baselineVersion`, `release.historyPolicy`, `release.invalidCommitPolicy`, `hooks.enabled`, `hooks.path`, `update.check`.

Notas:

- Sin argumentos en una terminal interactiva, abre un menu.
- Sin argumentos en CI o modo no interactivo, imprime la configuracion efectiva.
- `get` no modifica archivos.
- `set` modifica la configuracion local del repositorio.
- Gestionar `hooks.installed` y `hooks.tasks` con comandos `conte hooks`.

## `conte history`

Registra el baseline de adopcion para repositorios que ya tienen historial Git.

Uso:

```bash
conte history adopt
conte history adopt --from HEAD
conte history adopt --from <ref> --version 1.2.3 --yes
```

Comportamiento:

- valida que `--from` resuelva a un commit
- escribe `release.baselineRef`
- escribe `release.baselineVersion` desde `--version` o `version.current`
- fija `release.historyPolicy=ignore-before-baseline`
- fija `release.invalidCommitPolicy=fail-after-baseline`

Usarlo cuando `conte release preview` informa:

```text
No release baseline found. Run: conte history adopt --from HEAD
```

## `conte uninstall`

Desinstala la CLI de Conte de este sistema.

Uso:

```bash
conte uninstall
conte uninstall --yes
conte uninstall -y
```

Opciones:

- `-y`, `--yes`: desinstala sin confirmacion interactiva.
- `-h`, `--help`: muestra ayuda.

Comportamiento:

- No requiere estar dentro de un repositorio Git.
- Resuelve el directorio de instalacion desde `CONTE_INSTALL_ROOT`, luego `CONTE_HOME`, luego el valor por defecto de la plataforma (`~/.conte` en Linux/macOS, `%USERPROFILE%\.conte` en Windows).
- Rechaza rutas de instalacion inseguras: directorio home, raiz del sistema de archivos, raiz de unidad, o directorio sin payload valido de Conte.
- Elimina los archivos de instalacion de Conte CLI y limpia entradas de PATH y variables de entorno donde sea seguro identificarlas.
- Nunca elimina directorios `.conte` locales de repositorios.

Notas:

- Para eliminar la configuracion local de Conte de un repositorio, usar `conte remove` dentro del repositorio.
- Abrir una terminal nueva despues de desinstalar para que los cambios de PATH y variables de entorno sean visibles.
- `conte self uninstall` es un alias obsoleto de `conte uninstall`.

## `conte remove`

Elimina solo el estado local del repositorio gestionado por Conte.

Uso:

```bash
conte remove
conte remove --yes
conte remove -y
```

Opciones:

- `-y`, `--yes`: elimina sin confirmacion interactiva.
- `-h`, `--help`: muestra ayuda.

Comportamiento:

- Es mutante y requiere estar dentro de un repositorio Git.
- Elimina solo paths gestionados por Conte bajo `<repo>/.conte`.
- Preserva archivos no gestionados, `.git`, archivos fuente y la instalacion global.
- Limpia `core.hooksPath` y `commit.template` solo cuando siguen apuntando a paths gestionados por Conte.
- Para desinstalar la CLI global, usar `conte uninstall`.

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
- Si workspace falta o esta deshabilitado, muestra `Workspace: disabled` y no lo trata como error.
- Si workspace esta habilitado, muestra modo de release, deteccion de servicios, cantidad de servicios y cada servicio con nombre, path y version.
- Para diagnosticos detallados, usar `conte doctor`.

## `conte doctor`

Ejecuta diagnosticos completos de la CLI/runtime de Conte y del repositorio.

Uso:

```bash
conte doctor
conte doctor -f
conte doctor --fix-interactive
```

Opciones:

- `-f`, `--fix`: aplica solo reparaciones seguras locales al repositorio.
- `--fix-interactive`: pregunta antes de aplicar fixes seguros cuando hay TTY.
- `--no-interactive`: desactiva prompts de reparacion.
- `-h`, `--help`: muestra ayuda.

Notas:

- `conte doctor` no modifica archivos.
- `conte doctor` muestra secciones de CLI/runtime, separacion de comandos, diagnosticos del repositorio, hooks y config.
- Si workspace falta o esta deshabilitado, lo informa como `disabled` y no falla por ese motivo.
- Si workspace esta habilitado, valida modo de release, deteccion de servicios, campos requeridos, paths de servicios, prefijos de tags, paths de changelog, politica multi-servicio y scopes compartidos.
- `conte doctor` separa `conte uninstall` como desinstalacion global/de sistema, `conte remove` como limpieza local del repositorio, y `conte self uninstall` como alias obsoleto.
- `conte doctor --fix` puede reinstalar hooks gestionados, configurar `core.hooksPath=.conte/hooks`, actualizar estado local de hooks y reinstalar el commit template gestionado.
- `conte doctor --fix` no desinstala la CLI global; usar `conte uninstall` para la desinstalacion global/de sistema.
- `conte doctor --fix` no elimina estado local de Conte del repositorio; usar `conte remove` para limpieza local del repositorio.
- No sobreescribe archivos no gestionados sin una ruta de reparacion explicita.

## `conte validate`

Ejecuta validaciones explicitas sin pasar por hooks Git.

Uso:

```bash
conte validate commit "fix(auth): corregir token"
conte validate commit -F .git/COMMIT_EDITMSG
conte validate branch
conte validate branch feat/add-login
conte validate repo
conte validate workspace
conte validate workspace -r main..HEAD
```

Notas:

- `commit <message>` valida un mensaje Conventional Commit con scope obligatorio.
- `commit -F, --file <path>` valida un mensaje leido desde archivo.
- `branch` valida la rama actual.
- `branch <name>` valida una rama indicada sin hacer checkout.
- `commit` y `branch` usan la configuracion del repositorio cuando existe; antes de `conte init`, usan defaults internos de CI para Conventional Commits con scope y familias de ramas.
- `repo` valida configuracion, workflow, mapeo de ramas y consistencia de hooks.
- `workspace` valida configuracion workspace/monorepo y reglas commit-a-servicio.
- `workspace -r, --range <base>..<head>` valida un rango explicito para CI o revisiones puntuales.
- La validacion workspace exige `name`, `path`, `tagPrefix`, `changelogFile` y `version` por servicio; las rutas deben ser unicas y no solaparse.
- Los commits workspace mantienen scopes Conventional Commit cortos (`^[a-z0-9-]+$`), fallan si afectan varios servicios con `multiServicePolicy=fail`, y los commits fuera de rutas de servicio requieren un scope de `workspace.sharedScopes`.
- Workspace es opt-in desde `conte init --workspace`. Para service mode se puede usar `conte init --workspace --release-mode service --service orders-api --service-path services/orders-api`, y luego `conte workspace add-service orders-api --path services/orders-api` para registrar servicios adicionales. El scope del commit sigue representando ticket/historia/issue, no el nombre del servicio.
- CI/CD debe ejecutar `conte validate workspace` y, cuando `workspace.enabled=true` con `workspace.releaseMode=service`, `conte release preview --all-services`.
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
conte hooks install -f
conte hooks reinstall -f
conte hooks uninstall
conte hooks doctor
conte hooks test commit-msg "fix(auth): corregir token"
conte hooks test branch feat/add-login
conte hooks task
conte hooks task list
conte hooks task --help
conte hooks task add dotnet-test -H pre-push -- dotnet test
conte hooks task edit dotnet-test -n dotnet-test-all -H manual -e -- dotnet test
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
- `commit-msg` valida solo el formato Conventional Commit con scope obligatorio; no inspecciona archivos cambiados ni resuelve servicios workspace.
- `pre-push` valida rangos de commits enviados con reglas workspace commit-a-servicio cuando `workspace.enabled=true`.
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
conte hooks task add dotnet-test -H pre-push -- dotnet test
conte hooks task add slow-check -H manual -d -- ./check.sh
conte hooks task edit dotnet-test -n dotnet-test-all -H manual -e -- dotnet test
conte hooks task remove dotnet-test
conte hooks task enable dotnet-test
conte hooks task disable dotnet-test
conte hooks task run dotnet-test
conte hooks task menu
```

Sintaxis:

- `conte hooks task add <name> -H, --hook <hook|manual> [-d, --disabled] -- <command>`
- `conte hooks task edit <name> [-n, --name <new-name>] [-H, --hook <hook|manual>] [-e, --enable|-D, --disable] [-- <command>]`

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
conte self update -c
conte self update -v 1.2.3
```

Subcomandos:

- `version`: equivalente a `conte version`.
- `update`: delega a `conte update` y acepta `-c, --check` y `-v, --version <x.y.z>`.
- `uninstall`: alias obsoleto de `conte uninstall`.

`self version` y `self update --check` no modifican archivos. `self update` puede modificar la instalacion global. `self uninstall` es un alias obsoleto; usar `conte uninstall` para desinstalar la CLI global. `conte uninstall` no afecta la configuracion local del repositorio. Usar `conte remove` dentro de un repositorio para quitar la configuracion local de Conte.

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
conte release preview -e
conte release preview --scope us-12
conte release preview -s us-12
conte release preview --service api
conte release preview -S api
conte release preview --scope-mode strict
conte release preview -m strict
conte release preview -i
conte release preview -n
conte release preview -C
conte release preview --full-history
conte release create
conte release create -e
conte release create --scope us-12
conte release create -s us-12
conte release create --scope us-12 --scope-mode strict
conte release create -s us-12 -m strict
conte release create --service api
conte release create -S api
conte release create -i
conte release create -n
conte release create -C
conte release create --full-history
conte release sync-develop
conte release sync-develop -p
```

Opciones de `preview` y `create`:

- `-e`, `--allow-empty-release`: permite release sin commits versionables.
- `-s`, `--scope <scope>`: limita el release a commits con ese scope exacto.
- `-S`, `--service <name>`: alias corto canonico para servicio.
- `-m`, `--scope-mode <full|strict>`: controla el modo scoped.
- `-i`, `--include-internal`: incluye commits internos con scope `release` en el changelog.
- `-n`, `--no-tag`: crea release sin tag Git.
- `-C`, `--no-changelog`: crea release sin escribir `CHANGELOG.md`.
- `--full-history`: permite explicitamente escanear todo el historial cuando no hay marker ni baseline.

Notas:

- `conte release preview` es un dry-run seguro y no escribe archivos.
- Por defecto, release y changelog no escanean todo el historial en repositorios con mas de un commit y sin marker/baseline.
- `conte release create` es mutante: actualiza config/changelog y crea tag salvo opciones que lo omitan.
- `conte release sync-develop [-p, --preview]` esta disponible solo para GitFlow segun el codigo.
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
