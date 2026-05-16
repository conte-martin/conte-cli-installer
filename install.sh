#!/usr/bin/env bash
# Conte CLI public installer
# Usage: curl -fsSL https://raw.githubusercontent.com/conte-martin/conte-cli-installer/main/install.sh | bash
set -euo pipefail

CONTE_HOME="${CONTE_HOME:-$HOME/.conte}"
CONTE_BIN_DIR="$CONTE_HOME/bin"
CONTE_RELEASE_METADATA_URL="${CONTE_RELEASE_METADATA_URL:-https://github.com/conte-martin/conte-cli-installer/releases/latest/download/latest.json}"
CONTE_VERSION="${CONTE_VERSION:-}"
CONTE_VERBOSE="${CONTE_VERBOSE:-false}"

log() {
  [ "$CONTE_VERBOSE" = "true" ] && printf '[conte] %s\n' "$1" >&2 || true
}

info() {
  printf '%s\n' "$1"
}

warn() {
  printf 'Warning: %s\n' "$1" >&2
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1. Please install it and retry."
}

cleanup() {
  [ -n "${TMP_DIR:-}" ] && [ -d "${TMP_DIR:-}" ] && rm -rf "$TMP_DIR" || true
}

trap cleanup EXIT

detect_os() {
  local uname_out
  uname_out="$(uname -s)"
  case "$uname_out" in
    Linux*)             DETECTED_OS="linux";   ARCHIVE_EXT="tar.gz" ;;
    Darwin*)            DETECTED_OS="macos";   ARCHIVE_EXT="tar.gz" ;;
    MINGW*|MSYS*|CYGWIN*) DETECTED_OS="windows"; ARCHIVE_EXT="zip"  ;;
    *)                  fail "Unsupported operating system: $uname_out" ;;
  esac
}

detect_arch() {
  local uname_m
  uname_m="$(uname -m)"
  case "$uname_m" in
    x86_64|amd64)  DETECTED_ARCH="x64"  ;;
    arm64|aarch64) DETECTED_ARCH="arm64" ;;
    *)             fail "Unsupported architecture: $uname_m" ;;
  esac
}

select_metadata_key() {
  case "${DETECTED_OS}:${DETECTED_ARCH}" in
    linux:x64)     METADATA_KEY="linux_x64_url"  ;;
    linux:arm64)   METADATA_KEY="linux_arm64_url" ;;
    macos:x64)     METADATA_KEY="macos_x64_url"   ;;
    macos:arm64)   METADATA_KEY="macos_arm64_url"  ;;
    windows:x64)   METADATA_KEY="windows_x64_url" ;;
    windows:arm64) fail "Windows arm64 is not supported. Use install.ps1 on a Windows x64 system." ;;
    *)             fail "Unsupported platform: ${DETECTED_OS} ${DETECTED_ARCH}" ;;
  esac
}

extract_json_string() {
  local json="$1"
  local key="$2"
  printf '%s' "$json" \
    | tr -d '\r\n' \
    | sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
}

fetch_metadata() {
  local url="$CONTE_RELEASE_METADATA_URL"

  if [ -n "$CONTE_VERSION" ]; then
    url="$(printf '%s' "$url" | sed 's|/releases/latest/download/|/releases/download/'"$CONTE_VERSION"'/|')"
  fi

  log "Fetching release metadata from $url"
  METADATA_JSON="$(curl -fsSL "$url")" \
    || fail "Failed to fetch release metadata from: $url -- check your internet connection."

  RELEASE_VERSION="$(extract_json_string "$METADATA_JSON" "version")"
  [ -n "$RELEASE_VERSION" ] \
    || fail "Invalid release metadata: could not parse version field from $url"

  ASSET_URL="$(extract_json_string "$METADATA_JSON" "$METADATA_KEY")"
  [ -n "$ASSET_URL" ] \
    || fail "Platform URL not found in release metadata (key: $METADATA_KEY). This platform may not be supported yet."

  CHECKSUMS_URL="$(extract_json_string "$METADATA_JSON" "checksums_url")"
  [ -n "$CHECKSUMS_URL" ] \
    || fail "checksums_url not found in release metadata"

  ASSET_NAME="$(basename "$ASSET_URL")"
}

resolve_sha256_tool() {
  if command -v sha256sum >/dev/null 2>&1; then
    SHA256_CMD="sha256sum"
  elif command -v shasum >/dev/null 2>&1; then
    SHA256_CMD="shasum -a 256"
  else
    fail "No SHA256 tool found. Install sha256sum (Linux) or shasum (macOS) and retry."
  fi
}

compute_sha256() {
  $SHA256_CMD "$1" | sed 's/[[:space:]].*//'
}

extract_expected_checksum() {
  local checksum_file="$1"
  local asset_name="$2"
  local checksum
  checksum="$(grep -E "(^|[[:space:]])\*?${asset_name}$" "$checksum_file" \
    | sed 's/[[:space:]].*//' \
    | head -n 1 || true)"
  [ -n "$checksum" ] \
    || fail "Checksum entry not found for $asset_name in checksums.txt"
  printf '%s' "$checksum"
}

extract_archive() {
  local archive="$1"
  local dest="$2"
  mkdir -p "$dest"
  case "$ARCHIVE_EXT" in
    tar.gz) tar -xzf "$archive" -C "$dest" ;;
    zip)    unzip -q -o "$archive" -d "$dest" ;;
    *)      fail "Unsupported archive type: $ARCHIVE_EXT" ;;
  esac
}

find_binary() {
  local dir="$1"
  local found
  found="$(find "$dir" -type f \( -name 'conte' -o -name 'conte.exe' \) | head -n 1 || true)"
  [ -n "$found" ] || fail "conte executable not found in the downloaded package"
  printf '%s' "$found"
}

find_cmd_wrapper() {
  local dir="$1"
  find "$dir" -type f -name 'conte.cmd' 2>/dev/null | head -n 1 || true
}

print_path_instructions() {
  case ":${PATH:-}:" in
    *":$CONTE_BIN_DIR:"*) return ;;
  esac

  printf '\n'
  printf '  Next steps -- add conte to your PATH:\n'
  printf '\n'

  if [ "$DETECTED_OS" = "windows" ]; then
    local win_path
    win_path="$(cygpath -w "$CONTE_BIN_DIR" 2>/dev/null || printf '%s' "$CONTE_BIN_DIR")"
    printf '  Run once in PowerShell to add permanently:\n'
    printf '    [System.Environment]::SetEnvironmentVariable("PATH", "$env:PATH;%s", "User")\n' "$win_path"
    printf '\n'
    printf '  Then open a new terminal and run: conte --version\n'
  else
    printf '  Add to your shell profile (~/.bashrc, ~/.zshrc, etc.):\n'
    printf '    export PATH="%s:$PATH"\n' "$CONTE_BIN_DIR"
    printf '\n'
    printf '  Or apply immediately to the current session:\n'
    printf '    export PATH="%s:$PATH"\n' "$CONTE_BIN_DIR"
  fi

  printf '\n'
}

main() {
  require_command curl

  detect_os
  detect_arch
  select_metadata_key

  case "$ARCHIVE_EXT" in
    tar.gz) require_command tar   ;;
    zip)    require_command unzip ;;
  esac
  require_command grep
  require_command sed
  require_command find

  resolve_sha256_tool

  info "Detected: ${DETECTED_OS} ${DETECTED_ARCH}"

  TMP_DIR="$(mktemp -d)"

  fetch_metadata

  local archive_path="$TMP_DIR/$ASSET_NAME"
  local checksums_path="$TMP_DIR/checksums.txt"
  local extract_dir="$TMP_DIR/extracted"
  local target_bin

  if [ "$DETECTED_OS" = "windows" ]; then
    target_bin="$CONTE_BIN_DIR/conte.exe"
  else
    target_bin="$CONTE_BIN_DIR/conte"
  fi

  info "Installing Conte CLI ${RELEASE_VERSION}..."

  log "Downloading $ASSET_NAME"
  curl -fsSL "$ASSET_URL" -o "$archive_path" \
    || fail "Failed to download $ASSET_NAME"

  log "Downloading checksums.txt"
  curl -fsSL "$CHECKSUMS_URL" -o "$checksums_path" \
    || fail "Failed to download checksums.txt"

  local expected_sum actual_sum
  expected_sum="$(extract_expected_checksum "$checksums_path" "$ASSET_NAME")"
  actual_sum="$(compute_sha256 "$archive_path")"
  [ "$expected_sum" = "$actual_sum" ] \
    || fail "Checksum mismatch for $ASSET_NAME (expected: $expected_sum, got: $actual_sum)"
  log "Checksum OK"

  extract_archive "$archive_path" "$extract_dir"

  local src_binary
  src_binary="$(find_binary "$extract_dir")"

  mkdir -p "$CONTE_BIN_DIR"
  cp "$src_binary" "$target_bin"
  chmod +x "$target_bin"

  if [ "$DETECTED_OS" = "windows" ]; then
    local cmd_wrapper
    cmd_wrapper="$(find_cmd_wrapper "$extract_dir")"
    if [ -n "$cmd_wrapper" ]; then
      cp "$cmd_wrapper" "$CONTE_BIN_DIR/conte.cmd"
      log "Installed conte.cmd wrapper"
    fi
  fi

  if "$target_bin" --version >/dev/null 2>&1; then
    info "Installed: $("$target_bin" --version)"
  else
    info "Installed Conte CLI ${RELEASE_VERSION} to $target_bin"
    warn "Could not verify with --version"
  fi

  print_path_instructions
}

# Guard: set CONTE_INSTALLER_NO_EXEC=1 when sourcing this file for testing
if [ "${CONTE_INSTALLER_NO_EXEC:-}" != "1" ]; then
  main "$@"
fi
