# Release

## Comando

```bash
conte release preview
conte release create
conte release create --scope us-12
```

## Modelo De Comandos

Conte usa dos superficies de version distintas:

- `conte version` informa solo la version instalada de la CLI
- `conte semver *` administra el estado de version del proyecto guardado en `.conte/config.json`

La creacion de releases es explicita:

- `conte release preview`: previsualiza sin escribir archivos
- `conte release create`: crea artefactos de release, actualiza changelog/config y crea el tag segun la configuracion

`conte semver` queda separado del release operativo:

- `conte semver get` muestra la version actual del proyecto.
- `conte semver next` calcula e imprime solo la proxima version del proyecto.
- `conte semver set <version>` establece la version del proyecto.
- `conte semver breaking` marca el proximo release como MAJOR.
- `conte release create` lee commits, calcula la version, escribe el estado del release, crea el commit de release y crea el tag

Para operaciones mutantes de release, Conte lee y escribe el mismo `.conte/config.json` local del repositorio.
La configuracion de workspace o global puede seguir afectando comandos de inspeccion, pero no `conte semver set`, `conte semver breaking` ni `conte release create`.

## Flujo De Release

El comando realiza estos pasos:

1. carga `.conte/config.json`
2. resuelve workflow y branch mapping logico
3. valida el estado del repositorio y exige working tree limpio
4. encuentra el ultimo tag `vX.Y.Z`
5. lee commits no-merge desde ese tag
6. valida esos commits
7. calcula la siguiente version SemVer
8. en modo scoped y solo en workflows soportados crea `release/<scope>` y hace cherry-pick solo de los commits seleccionados
9. actualiza `version.current` y limpia `version.breaking`
10. genera o actualiza `CHANGELOG.md`
11. crea el commit de release gestionado por Conte
12. crea `vX.Y.Z` salvo que se use `--no-tag`
13. imprime el resumen del release

El comando es determinista:

- `version.current` guarda SemVer sin prefijo
- `version.breaking` guarda el override major del proximo release como `true` o `false`
- los tags Git usan `vX.Y.Z`
- el input del release es el historial de commits desde el ultimo marker de release: el ultimo tag `v*` relevante, o el ultimo commit de release de Conte cuando existe un release `--no-tag` mas nuevo
- los merge commits se ignoran
- commits Conventional Commits no-merge invalidos hacen fallar el release antes del calculo de version
- el scope del commit es obligatorio
- la descripcion del commit puede usar mayusculas o minusculas

Cuando se usa `--no-tag`, el commit de release (`chore(release): cut vX.Y.Z`) es el marker durable. Una segunda ejecucion de `conte release create --no-tag` sin commits versionables nuevos termina de forma segura en vez de crear otro commit de release o duplicar la seccion del changelog.

## Releases Scoped

`--scope <scope>` limita el release a commits cuyo scope parseado de Conventional Commits coincide exactamente.

Ejemplos válidos:

- `feat(us-12): add endpoint`
- `fix(us-12): handle error`
- `perf(us-12): optimize query`

No coincide con:

- `us-123`
- `core-us-12`
- `us-12-extra`

Comandos soportados:

```bash
conte release create --scope us-12
```

Comportamiento:

1. valida el scope contra la regla canonica de scopes de commit de Conte y `commit.scopePattern`
2. valida workflow y branch mapping antes de escribir
3. en workflows soportados crea `release/<scope>` desde la branch base mapeada
4. hace cherry-pick de commits seleccionados cuando la rama origen no es la branch base mapeada
5. calcula version y changelog usando solo esos commits
6. actualiza `.conte/config.json`, `CHANGELOG.md`, crea el commit de release y crea `vX.Y.Z`

Workflows soportados:

- `gitflow` desde la rama `develop` mapeada

Workflows rechazados:

- `trunk`
- `kanban`

En `kanban`, el release normal puede ejecutarse desde la branch `main` mapeada, pero no crea ni requiere ramas `release/*` por defecto.

Puede fallar si los commits del scope seleccionado dependen de commits fuera de ese scope.

## Reglas SemVer Scoped

- `feat(scope): ...` -> minor
- `fix(scope): ...` -> patch
- `perf(scope): ...` -> patch
- `conte semver breaking` -> major en el proximo release exitoso

`conte semver breaking` escribe el marker breaking en `.conte/config.json`. Commitear ese archivo antes de crear el release:

```bash
git add .conte/config.json
git commit -m "chore(release): mark next version as major"
conte release create
```

Si no hay commits versionables para el scope seleccionado, falla salvo que se use `--allow-empty-release`. En ese caso Conte fuerza un patch. Los marcadores de breaking (`!` despues del scope, `BREAKING CHANGE` en el footer) no forman parte del formato v1. Solo `conte semver breaking` activa un release MAJOR. Los subjects de merge commits se ignoran porque la recoleccion usa `git log --no-merges`.

## Version Vs Tag

- `version.current` guarda SemVer sin prefijo
- los tags Git usan `vX.Y.Z`
- si todavia no existe un tag de release, Conte usa `version.current` como baseline

## Artefactos Hosted De Release

El repositorio core produce los artefactos de release y mantiene el contrato de metadata. El workflow por tag se ejecuta con `vX.Y.Z`, crea los artefactos de Linux, macOS, ZIP de Windows e instalador de Windows, genera `checksums.txt`, y escribe `latest.json` con SemVer sin prefijo y URLs publicas.

`latest.json` apunta a assets publicos en `conte-martin/conte-cli-installer` para que la instalacion sin token y `conte update` no requieran `GITHUB_TOKEN`.

La publicacion hosted se divide entre el repositorio privado de codigo fuente y el repositorio publico de instaladores:

1. Pushear el tag `vX.Y.Z` a `conte-cli`.
2. `conte-cli` construye artefactos y crea el GitHub Release privado.
3. `conte-cli` dispara `repository_dispatch` en `conte-martin/conte-cli-installer` con event type `publish-release` usando `GITHUB_TOKEN`.
4. `conte-cli-installer` descarga assets privados usando `CONTE_CLI_TOKEN`.
5. `conte-cli-installer` crea el release publico con assets publicos y `latest.json`.

Secrets requeridos en GitHub Actions:

- `conte-cli`: ningun secret custom de release; el workflow usa `GITHUB_TOKEN`
- `conte-cli-installer`: `CONTE_CLI_TOKEN`

`CONTE_CLI_TOKEN` debe poder leer assets privados desde `conte-martin/conte-cli` y permitir que el workflow publico cree o actualice el release publico. El workflow privado no imprime valores de tokens.
