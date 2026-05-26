# Estado Del Repositorio

Conte CLI trata el directorio local `.conte` del repositorio como un contrato de enforcement, no como un cache.

El estado local del repositorio debe vivir en:

- `<repo>/.conte/config.json`
- `<repo>/.conte/hooks/` para los hooks Git gestionados por Conte

Cuando los hooks estan habilitados, Git tambien debe usar:

```bash
git config --local core.hooksPath .conte/hooks
```

## Estados Validos

### No inicializado

Hechos requeridos:

- `<repo>/.conte/config.json` no existe

Comportamiento esperado:

- `conte init` crea `.conte/config.json`
- `conte status` informa `Not initialized`
- `conte doctor` informa que Conte no esta inicializado
- `conte release create` falla porque falta la config local del repositorio
- `conte uninstall` sale limpio e informa que el repositorio no esta inicializado

### Inicializado con hooks habilitados

Hechos requeridos:

- `<repo>/.conte/config.json` existe
- `hooks.enabled=true`
- `hooks.path=.conte/hooks`
- `<repo>/.conte/hooks/commit-msg` existe
- `<repo>/.conte/hooks/pre-push` existe
- `<repo>/.conte/hooks/prepare-commit-msg` existe
- `<repo>/.conte/hooks/pre-commit` existe
- cada hook configurado es ejecutable
- el runtime de cada hook configurado resuelve correctamente la instalacion de Conte
- `git config --local core.hooksPath` es `.conte/hooks`

Comportamiento esperado:

- `conte init` verifica el estado final de hooks despues de escribir config e instalar hooks
- `conte hooks install` y `conte hooks reinstall --force` pueden reparar el estado gestionado
- `conte status` informa alineacion de hooks y actividad de validacion de commits y ramas
- `conte doctor` valida config, archivos de hooks, permisos de ejecucion, runtime, branch mapping, validez de rama actual y validez de commits para release
- `conte release create` valida commits no-merge desde el ultimo tag antes de calcular la siguiente version
- `conte uninstall` elimina archivos gestionados por Conte dentro de `<repo>/.conte`, preserva contenido no gestionado y limpia `core.hooksPath` solo cuando coincide con el path gestionado configurado

### Inicializado con hooks deshabilitados

Hechos requeridos:

- `<repo>/.conte/config.json` existe
- `hooks.enabled=false`
- `core.hooksPath` no necesita apuntar a `.conte/hooks`

Comportamiento esperado:

- `conte init` imprime una advertencia explicita indicando que la validacion local de commits y ramas esta inactiva
- `conte hooks status` informa hooks deshabilitados/inactivos
- `conte status` informa que el repositorio esta inicializado con hooks deshabilitados
- `conte doctor` advierte sobre la validacion local inactiva, pero esa advertencia sola no hace fallar el comando
- `conte release create` igual valida commits no-merge desde el ultimo tag
- `conte uninstall` elimina solo `<repo>/.conte`

### Roto o inconsistente

Ejemplos:

- `.conte/config.json` existe pero `core.hooksPath` falta cuando `hooks.enabled=true`
- `hooks.enabled=true` pero `core.hooksPath` apunta a otro lado
- faltan hooks configurados
- hooks configurados no son ejecutables
- el runtime de hooks configurados esta roto
- el branch mapping apunta a ramas locales inexistentes
- la rama actual viola el workflow seleccionado
- los commits no-merge desde el ultimo release contienen Conventional Commits invalidos

Comportamiento esperado:

- `conte status` informa el estado roto del repositorio y las areas especificas fallidas
- `conte doctor` sale non-zero e imprime errores accionables
- `conte init` aborta si no puede verificar el estado final de hooks habilitados y sugiere:

```bash
conte hooks reinstall --force
```

## Expectativas Por Comando

### `conte init`

- escribe `<repo>/.conte/config.json`
- instala hooks cuando estan habilitados
- verifica el estado final despues de escribir config
- imprime config path, hooks enabled, hooks path, `core.hooksPath` y si la validacion de commits y ramas esta activa
- advierte explicitamente cuando los hooks estan deshabilitados

### `conte hooks install`

- escribe hooks gestionados por Conte en `<repo>/.conte/hooks`
- configura `core.hooksPath=.conte/hooks`
- preserva paths de hooks no relacionados fuera del path configurado por Conte

### `conte hooks uninstall`

- elimina archivos gestionados por Conte del hooks path configurado
- limpia `hooks.enabled`
- preserva archivos no gestionados por Conte

### `conte status`

- muestra si el repositorio no esta inicializado, esta inicializado con hooks habilitados, esta inicializado con hooks deshabilitados o esta roto
- muestra alineacion de hooks, runtime de hooks, actividad de validacion, salud del branch mapping, salud de la rama actual y salud de commits para release

### `conte doctor`

- valida en profundidad el contrato local del repositorio
- trata hooks deshabilitados como advertencia
- trata hook/config/runtime roto como falla

### `conte release create`

- lee solo commits no-merge
- rechaza Conventional Commits no-merge invalidos desde el ultimo tag
- ignora los subjects de merge commits porque la recoleccion usa `git log --no-merges`

### `conte uninstall`

- lee `hooks.path` configurado antes de eliminar `<repo>/.conte`
- limpia `core.hooksPath` solo cuando coincide con el path gestionado configurado
- preserva valores no relacionados de `core.hooksPath`
- elimina solo `<repo>/.conte` despues de validar seguridad del path
