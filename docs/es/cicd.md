# CI/CD

## Principio

Conte trata CI/CD como la autoridad remota de enforcement:

```text
Hooks locales -> experiencia del desarrollador
CI/CD -> enforcement
CLI -> fuente unica de comportamiento
```

Los hooks locales ayudan, pero CI debe ser la capa real porque los hooks pueden omitirse.

## Workflows del repositorio Conte CLI

El repositorio separa la validacion por momento de merge:

- `ci-pr.yml` valida pull requests hacia `main`, `master` o `develop`. Revisa reglas de rama, commits con scope obligatorio, sintaxis Bash, tests rapidos, smoke integration y suites enfocadas para hooks, release, workspace y uninstall cuando cambian rutas relacionadas.
- `ci-main.yml` valida el estado integrado despues de un push a `main` o `master`: suite completa en Linux con paralelismo limitado, checks sensibles multiplataforma, preview de release desde tags reales y dry run de paquetes en Windows.
- `ci-scheduled.yml` corre semanalmente o manualmente para detectar drift de plataforma, instalador, packaging y toolchain.
- `ci-release.yml` es el unico workflow que publica releases. Corre solo para tags `vX.Y.Z`, valida que el tag venga de `origin/main` u `origin/master`, construye artefactos, checksums y metadata, y publica la release privada antes de disparar la release publica del instalador.

## Proteccion de ramas

Checks recomendados antes de merge:

- `Branch and commit validation`
- `Syntax and fast tests`
- `Workspace validation` cuando hay cambios de codigo
- `Integration smoke` cuando hay cambios de codigo

`Hooks-sensitive tests`, `Release-sensitive tests`, `Workspace-sensitive tests`, `Uninstall-sensitive tests`, `Windows-sensitive tests` y `Package dry run` deben ser visibles y requeridos solo cuando sus rutas relacionadas cambian. La revision de documentacion queda en el review normal, sin un job requerido separado para links/rutas. `Main CI`, `Scheduled CI` y `Release CI` no son checks de PR: validan historial integrado, drift y publicacion.

La estrategia local de suites y `CONTE_TEST_JOBS` esta documentada en [`docs/testing.md`](../testing.md).

La estrategia de changelog sigue basada en Conventional Commits y tags. No se usan titulos de PR, mensajes de merge ni entradas manuales como fuente de release notes.
