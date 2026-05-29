# Instalacion

## Instalacion publica sin token

Linux/macOS:

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

El repositorio publico `conte-martin/conte-cli-installer` expone scripts de instalacion y metadata publica. No se requiere `GITHUB_TOKEN`.

Ubicaciones por defecto:

- Linux/macOS: `~/.conte`, ejecutable en `~/.conte/bin`
- Windows: `%USERPROFILE%\.conte`, ejecutable en `%USERPROFILE%\.conte\bin`

Verificar:

```bash
conte --version
conte doctor
```

`conte update` usa por defecto `https://github.com/conte-martin/conte-cli-installer/releases/latest/download/latest.json`, verifica SHA256 con `checksums.txt`, y permite override con `CONTE_RELEASE_METADATA_URL`.

Los scripts `install.sh`, `install.ps1` e `install.cmd` en la raiz de este repositorio son los instaladores publicos curl-pipe. El tarball de release de Conte CLI incluye su propio `install.sh` interno que opera desde el arbol descomprimido, util para instalaciones offline desde un artefacto descargado.

## Windows (Git Bash)

Conte requiere [Git for Windows](https://git-scm.com/download/win) para ejecutarse en Windows.

Usar el instalador `.exe` cuando sea posible:

- descargar `conte-cli-installer-windows-x64.exe`
- instalar en `%USERPROFILE%\.conte`
- dejar `%USERPROFILE%\.conte\bin` en el `PATH` del usuario
- abrir una terminal nueva
- ejecutar `conte --version`
- ejecutar `conte doctor`

El instalador agrega `%USERPROFILE%\.conte\bin` al `PATH` del usuario e instala `conte.cmd`.

Si se usa el ZIP o una instalacion manual en Windows, usar el mismo destino:

- extraer en `%USERPROFILE%\.conte`
- asegurar `%USERPROFILE%\.conte\bin` en el `PATH` del usuario
- abrir una terminal nueva para refrescar el `PATH`

Conte no debe instalarse en `%LOCALAPPDATA%\Programs\.conte`, `C:\Program Files\.conte` ni `C:\Program Files (x86)\.conte`.
