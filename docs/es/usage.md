# Uso

## Comandos frecuentes

```bash
conte
conte help
conte menu
conte init
conte status
conte doctor
conte release preview
conte version
conte update
```

## Ayuda y dashboard

`conte` sin argumentos muestra un dashboard. Fuera de Git sugiere `conte init` y `conte help`; dentro de un repositorio inicializado muestra version de Conte, workflow, rama principal, rama actual, estado de hooks y proximos comandos.

`conte help`, `conte --help` y `conte -h` muestran ayuda agrupada por intencion: Getting started, Daily workflow, Release, Workspace, Configuration y System. `conte help <command>` muestra la ayuda especifica del comando.

Comandos u opciones desconocidas mantienen exit code distinto de cero y muestran `Did you mean?` cuando hay una sugerencia cercana.

## Menus interactivos

```bash
conte menu
conte init --interactive
conte release --interactive
conte doctor --fix-interactive
```

Los menus solo aparecen cuando stdin y stdout son TTY y no se detecta CI. Se desactivan con `--yes`, `--no-interactive`, `CI=true`, `GITHUB_ACTIONS`, `GITLAB_CI`, `TF_BUILD` o `BUILD_BUILDID`.

Equivalentes no interactivos:

```bash
conte init --yes
conte status
conte doctor --fix
conte release preview
conte release create --yes
```

## Color

Conte usa color semantico solo para salida humana en TTY. Por defecto no emite codigos ANSI cuando la salida esta redirigida.

```bash
CONTE_COLOR=auto
CONTE_COLOR=always
CONTE_COLOR=never
NO_COLOR=1
FORCE_COLOR=1
```

## Avisos de actualizacion

`conte`, `conte help`, `conte version`, `conte status` y `conte doctor` pueden mostrar un aviso cacheado si hay una version nueva. El resultado se guarda por 24 horas en `CONTE_HOME/cache` y nunca hace fallar el comando original.

Desactivar:

```bash
CONTE_UPDATE_CHECK=0
conte config set update.check false
```

`conte update` sigue siendo el comando explicito que instala actualizaciones.

## Aliases cortos

Las opciones largas son canonicas. Los aliases comunes incluyen `-h/--help`, `-v/--version`, `-y/--yes`, `-f/--force`, `-s/--scope`, `-S/--service`, `-w/--workflow`, `-m/--main-branch`, `-d/--develop-branch`, `-o/--output` y `-c/--config` cuando aplican al comando.
