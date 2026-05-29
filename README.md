# Conte CLI Installer

Instalador publico y punto de distribucion de [Conte CLI](https://github.com/conte-martin/conte-cli).

No requiere token. No requiere permisos de administrador.

## Que contiene este repositorio

Este repositorio publica los instaladores y assets necesarios para instalar Conte CLI desde GitHub Releases:

- `install.sh`: instalador para Linux, macOS y Windows con Git Bash.
- `install.ps1`: instalador para Windows PowerShell.
- `install.cmd`: instalador para Windows CMD; delega en `install.ps1`.
- `uninstall.sh`: desinstalador para Linux, macOS y Windows con Git Bash.
- `uninstall.ps1`: desinstalador para Windows PowerShell.
- GitHub Releases con binarios por plataforma, `checksums.txt` y `latest.json`.

Los instaladores descargan `latest.json` desde la ultima release publica de este repositorio, seleccionan el asset correcto para la plataforma, verifican el checksum SHA256 e instalan Conte CLI en `~/.conte` por defecto.

## Instalacion rapida

Linux / macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.ps1 | iex
```

Windows CMD:

```cmd
curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.cmd -o install.cmd && install.cmd && del install.cmd
```

## Linux y macOS

Instalar la ultima version:

```bash
curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.sh | bash
```

Instalar una version especifica:

```bash
CONTE_VERSION=v1.2.3 curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.sh | bash
```

Usar un directorio de instalacion personalizado:

```bash
CONTE_HOME=/opt/conte curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.sh | bash
```

Por defecto, el binario queda en:

```bash
~/.conte/bin/conte
```

### Dependencias

`install.sh` requiere herramientas comunes del sistema:

- `curl`
- `tar`
- `grep`
- `sed`
- `find`
- `sha256sum` en Linux o `shasum` en macOS

## Windows PowerShell

Instalar la ultima version:

```powershell
irm https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.ps1 | iex
```

El instalador de PowerShell:

1. Descarga `latest.json`.
2. Descarga `conte-cli-windows-x64.zip`.
3. Verifica el checksum SHA256.
4. Extrae e instala el payload en `%USERPROFILE%\.conte`.
5. Agrega `%USERPROFILE%\.conte\bin` al PATH de usuario.
6. Intenta verificar la instalacion con `conte --version`.

Instalar una version especifica:

```powershell
$env:CONTE_VERSION = "v1.2.3"
irm https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.ps1 | iex
```

Usar un directorio de instalacion personalizado:

```powershell
$env:CONTE_HOME = "$env:USERPROFILE\tools\conte"
irm https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.ps1 | iex
```

En Windows, Conte CLI usa `bin\conte.cmd` como wrapper para ejecutar el entrypoint Bash `bin\conte`.

Despues de instalar, abre una terminal nueva y ejecuta:

```powershell
conte --version
```

## Windows CMD

```cmd
curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.cmd -o install.cmd && install.cmd && del install.cmd
```

`install.cmd` valida que PowerShell este disponible y ejecuta `install.ps1` con `ExecutionPolicy Bypass`.

## Verificar instalacion

```bash
conte --version
```

Si `conte` no se encuentra, revisa la configuracion de PATH.

Tambien puedes ejecutar el entrypoint directamente:

```bash
# Linux / macOS
~/.conte/bin/conte --version
```

```powershell
# Windows PowerShell
& "$env:USERPROFILE\.conte\bin\conte.cmd" --version
```

```bash
# Windows Git Bash
~/.conte/bin/conte --version
```

## Actualizar Conte CLI

Para actualizar, vuelve a ejecutar el instalador. La instalacion existente se sobrescribe con la version publicada en la release seleccionada.

```bash
curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.sh | bash
```

En Windows:

```powershell
irm https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.ps1 | iex
```

## Desinstalar

Linux / macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/uninstall.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/uninstall.ps1 | iex
```

Windows CMD:

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/uninstall.ps1 | iex"
```

Para desinstalar desde un `CONTE_HOME` personalizado:

```bash
CONTE_HOME=/opt/conte curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/uninstall.sh | bash
```

`uninstall.sh` elimina el directorio de instalacion, pero no modifica perfiles de shell. Si agregaste `~/.conte/bin` manualmente a `~/.bashrc`, `~/.zshrc` o `~/.profile`, elimina esa linea.

`uninstall.ps1` elimina `%USERPROFILE%\.conte` y remueve del PATH de usuario la entrada que usa el instalador de PowerShell.

## Requisitos de Windows

- Windows 10 o superior, x64.
- PowerShell 5.0 o superior.
- Git for Windows recomendado para ejecutar Conte CLI, ya que Conte CLI es Bash-first en Windows.

Git for Windows se puede instalar desde:

```text
https://git-scm.com/download/win
```

## Configuracion de PATH

`install.ps1` agrega automaticamente el directorio `bin` al PATH de usuario. Abre una terminal nueva para que el cambio tenga efecto.

`install.sh` no modifica perfiles de shell. Agrega el directorio manualmente si es necesario:

```bash
export PATH="$HOME/.conte/bin:$PATH"
```

Para hacerlo permanente, agrega esa linea a `~/.bashrc`, `~/.zshrc` o `~/.profile`.

En Windows PowerShell, tambien puedes agregarlo manualmente:

```powershell
[System.Environment]::SetEnvironmentVariable('PATH', "$env:PATH;$env:USERPROFILE\.conte\bin", 'User')
```

## Variables del instalador

| Variable | Descripcion | Valor por defecto |
|---|---|---|
| `CONTE_HOME` | Directorio raiz de instalacion | `~/.conte` o `%USERPROFILE%\.conte` |
| `CONTE_VERSION` | Version especifica a instalar, por ejemplo `v1.2.3` | Ultima release |
| `CONTE_RELEASE_METADATA_URL` | URL alternativa para `latest.json` | Release `latest.json` |
| `CONTE_VERBOSE` | Muestra logs adicionales en `install.sh` si vale `true` | `false` |

## Troubleshooting

### `conte` no se encuentra despues de instalar

El directorio `bin` de Conte CLI no esta en PATH o la terminal actual no recibio el cambio.

En Windows, abre una terminal nueva despues de ejecutar `install.ps1`.

En Linux/macOS, agrega:

```bash
export PATH="$HOME/.conte/bin:$PATH"
```

### Error al descargar metadata

Verifica conectividad y que exista una release publica con `latest.json`:

```bash
curl -fsSL https://github.com/conte-martin/conte-cli-installer/releases/latest/download/latest.json
```

### Checksum mismatch

El archivo descargado no coincide con el checksum publicado. Borra la descarga temporal, vuelve a ejecutar el instalador y, si el error persiste, abre un issue:

```text
https://github.com/conte-martin/conte-cli-installer/issues
```

### Windows: error de execution policy

Ejecuta el instalador con bypass explicito:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.ps1 | iex"
```

### Windows: Git Bash no detectado

Instala Git for Windows:

```text
https://git-scm.com/download/win
```

Luego abre una terminal nueva y ejecuta:

```powershell
conte --version
```

## Seguridad

- Los assets se descargan por HTTPS.
- Cada descarga se valida con SHA256 antes de instalarse.
- `checksums.txt` se descarga desde la misma release que el binario.
- El instalador no requiere permisos de administrador.
- El instalador no configura actualizaciones automaticas.
- El instalador no envia telemetria ni analytics.

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE) for details.
