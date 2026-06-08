# Releases de servicios en workspace / monorepo

## Resumen

Conte puede publicar servicios de forma independiente dentro de un workspace o monorepo. En modo `service`, el scope del Conventional Commit sigue representando un ticket, historia, issue o contexto funcional corto. El servicio se detecta por la ruta de los archivos modificados.

Recomendado:

```text
feat(us-12): agregar confirmación de pedido
fix(issue-89): corregir validación de saldo
```

No recomendado:

```text
feat(orders-api-us-12): agregar confirmación de pedido
feat(orders-api): agregar confirmación de pedido
```

Regla clave:

```text
scope = ticket/historia/issue/contexto funcional corto
service = inferido por ruta de archivo
```

Ejemplo:

```text
Branch: feature/us-12-confirm-order
Commit: feat(us-12): agregar confirmación de pedido
Files: services/orders-api/src/ConfirmOrder.cs
Command: conte release preview --service orders-api
Tag: orders-api@1.4.0
```

## Configuracion

Ejemplo completo:

```json
{
  "workspace": {
    "enabled": true,
    "releaseMode": "service",
    "serviceDetection": "path",
    "scopeMeaning": "ticket",
    "multiServicePolicy": "fail",
    "scopePathValidation": "off",
    "sharedScopes": ["repo", "docs", "ci", "build", "deps"],
    "services": [
      {
        "name": "orders-api",
        "path": "services/orders-api",
        "tagPrefix": "orders-api@",
        "changelogFile": "services/orders-api/CHANGELOG.md",
        "version": "1.3.0"
      },
      {
        "name": "billing-api",
        "path": "services/billing-api",
        "tagPrefix": "billing-api@",
        "changelogFile": "services/billing-api/CHANGELOG.md",
        "version": "0.8.2"
      }
    ]
  }
}
```

Campos principales:

- `enabled`: activa o desactiva workspace
- `releaseMode`: `repository` o `service`
- `serviceDetection`: actualmente `path`
- `scopeMeaning`: `ticket` indica que el scope del commit representa ticket/historia, no un servicio
- `multiServicePolicy`: controla commits que tocan multiples servicios
- `scopePathValidation`: controla la validacion opcional scope/ruta; por defecto es `off`
- `sharedScopes`: scopes permitidos para cambios de repositorio
- `services`: definiciones de servicios

Campos de servicio:

- `name`: identificador del servicio
- `path`: raiz del servicio
- `tagPrefix`: prefijo de tags del servicio
- `changelogFile`: changelog del servicio
- `version`: version actual del servicio

## Deteccion por ruta

```text
services/orders-api/src/ConfirmOrder.cs -> orders-api
services/billing-api/src/Invoice.cs -> billing-api
README.md -> sin servicio / requiere shared scope
```

Conte evita falsos positivos: `services/api-v2/file.cs` no debe matchear el path `services/api`.

## Tags y changelogs

Formato recomendado de tag:

```text
<service>@<version>
```

Ejemplos:

```text
orders-api@1.4.0
billing-api@0.8.3
identity-api@2.1.0
```

Cada servicio tiene su propio changelog:

```text
services/orders-api/CHANGELOG.md
services/billing-api/CHANGELOG.md
```

Los commits que no afectan el path del servicio no se incluyen en el changelog de ese servicio. El agrupamiento es `type -> scope -> description`.

## multiServicePolicy

Recomendado:

```json
"multiServicePolicy": "fail"
```

Si un commit toca `orders-api` y `billing-api`, Conte falla con `multiServicePolicy=fail`. Las opciones `warn` y `allow` son modos planificados; el modo recomendado y soportado actualmente es `fail`.

## sharedScopes

```json
"sharedScopes": ["repo", "docs", "ci", "build", "deps"]
```

Cambios fuera de paths de servicio requieren un scope compartido:

```text
docs(repo): actualizar README
ci(repo): actualizar workflow
chore(deps): actualizar dependencias compartidas
```

Este commit se rechaza si solo modifica `README.md`:

```text
feat(us-12): actualizar README
```

## Comandos

```bash
conte release preview --service orders-api
conte release create --service orders-api
conte release create --service orders-api --yes
conte release preview --all-services
conte release create --all-services
conte release create --all-services --global
conte release create --all-services -g
conte validate workspace
conte status
conte doctor
conte init --workspace --release-mode service --service orders-api --service-path services/orders-api
conte workspace add-service orders-api --path services/orders-api
```

`conte workspace add-service` esta implementado y agrega un servicio detectado por ruta a `.conte/config.json`.

Usar `--global` reduce ruido de commits cuando se publican varios servicios juntos.
