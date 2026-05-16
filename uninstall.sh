#!/usr/bin/env bash
# Conte CLI uninstaller
# Usage: curl -fsSL https://raw.githubusercontent.com/conte-martin/Conte.CLI.Installer/main/uninstall.sh | bash
set -euo pipefail

CONTE_HOME="${CONTE_HOME:-$HOME/.conte}"

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

info() {
  printf '%s\n' "$1"
}

# Safety guards
[ -n "$CONTE_HOME" ] \
  || fail "CONTE_HOME is empty. Refusing to uninstall."
[ "$CONTE_HOME" != "/" ] \
  || fail "CONTE_HOME is set to /. Refusing to uninstall."
[ "$CONTE_HOME" != "$HOME" ] \
  || fail "CONTE_HOME is set to \$HOME. Refusing to uninstall."

if [ ! -d "$CONTE_HOME" ]; then
  info "Nothing to uninstall: $CONTE_HOME does not exist."
  exit 0
fi

info "Removing Conte CLI installation at $CONTE_HOME..."
rm -rf "$CONTE_HOME"
info "Removed: $CONTE_HOME"
info ""
info "Uninstall complete."
info ""
info "If you added $CONTE_HOME/bin to your shell profile manually,"
info "remove that line from ~/.bashrc, ~/.zshrc, or wherever you added it."
