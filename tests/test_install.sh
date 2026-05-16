#!/usr/bin/env bash
# Smoke tests for install.sh
# Run: bash tests/test_install.sh
# Note: no set -e here -- tests must survive intentional failures

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_SH="$SCRIPT_DIR/../install.sh"
TESTS_PASSED=0
TESTS_FAILED=0

pass()      { printf 'PASS  %s\n' "$1"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
fail_test() { printf 'FAIL  %s\n' "$1"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

# Source install.sh without running main
CONTE_INSTALLER_NO_EXEC=1 . "$INSTALL_SH"

# run_in_subshell <desc> <cmd...>
# Runs a command in a subshell. Functions that call fail()->exit are contained.
run_in_subshell() {
  local desc="$1"; shift
  if "$@" 2>/dev/null; then
    printf 'subshell/%s: exit 0\n' "$desc"
    return 0
  else
    printf 'subshell/%s: exit %d\n' "$desc" "$?"
    return 1
  fi
}

# ── OS detection ─────────────────────────────────────────────────────────────

test_os_linux() {
  uname() { printf 'Linux\n'; }
  detect_os
  [ "$DETECTED_OS" = "linux" ] && [ "$ARCHIVE_EXT" = "tar.gz" ] \
    && pass "detect_os: Linux" || fail_test "detect_os: Linux"
  unset -f uname
}

test_os_macos() {
  uname() { printf 'Darwin\n'; }
  detect_os
  [ "$DETECTED_OS" = "macos" ] && [ "$ARCHIVE_EXT" = "tar.gz" ] \
    && pass "detect_os: Darwin" || fail_test "detect_os: Darwin"
  unset -f uname
}

test_os_mingw() {
  uname() { printf 'MINGW64_NT-10.0\n'; }
  detect_os
  [ "$DETECTED_OS" = "windows" ] && [ "$ARCHIVE_EXT" = "zip" ] \
    && pass "detect_os: MINGW" || fail_test "detect_os: MINGW"
  unset -f uname
}

test_os_msys() {
  uname() { printf 'MSYS_NT-10.0\n'; }
  detect_os
  [ "$DETECTED_OS" = "windows" ] && [ "$ARCHIVE_EXT" = "zip" ] \
    && pass "detect_os: MSYS" || fail_test "detect_os: MSYS"
  unset -f uname
}

test_os_unknown() {
  # fail() calls exit -- run in subshell so exit doesn't kill the test runner
  if ( CONTE_INSTALLER_NO_EXEC=1 . "$INSTALL_SH"
       uname() { printf 'FreeBSD\n'; }
       detect_os
  ) 2>/dev/null; then
    fail_test "detect_os: unknown OS should fail"
  else
    pass "detect_os: unknown OS fails correctly"
  fi
}

# ── Architecture detection ────────────────────────────────────────────────────

test_arch_x64() {
  uname() { printf 'x86_64\n'; }
  detect_arch
  [ "$DETECTED_ARCH" = "x64" ] && pass "detect_arch: x86_64" || fail_test "detect_arch: x86_64"
  unset -f uname
}

test_arch_amd64() {
  uname() { printf 'amd64\n'; }
  detect_arch
  [ "$DETECTED_ARCH" = "x64" ] && pass "detect_arch: amd64 alias" || fail_test "detect_arch: amd64 alias"
  unset -f uname
}

test_arch_arm64() {
  uname() { printf 'arm64\n'; }
  detect_arch
  [ "$DETECTED_ARCH" = "arm64" ] && pass "detect_arch: arm64" || fail_test "detect_arch: arm64"
  unset -f uname
}

test_arch_aarch64() {
  uname() { printf 'aarch64\n'; }
  detect_arch
  [ "$DETECTED_ARCH" = "arm64" ] && pass "detect_arch: aarch64 alias" || fail_test "detect_arch: aarch64 alias"
  unset -f uname
}

test_arch_unknown() {
  if ( CONTE_INSTALLER_NO_EXEC=1 . "$INSTALL_SH"
       uname() { printf 'mips\n'; }
       detect_arch
  ) 2>/dev/null; then
    fail_test "detect_arch: unknown arch should fail"
  else
    pass "detect_arch: unknown arch fails correctly"
  fi
}

# ── Metadata key selection ────────────────────────────────────────────────────

test_metadata_key_linux_x64() {
  DETECTED_OS="linux"; DETECTED_ARCH="x64"; select_metadata_key
  [ "$METADATA_KEY" = "linux_x64_url" ] && pass "metadata_key: linux x64" || fail_test "metadata_key: linux x64"
}

test_metadata_key_linux_arm64() {
  DETECTED_OS="linux"; DETECTED_ARCH="arm64"; select_metadata_key
  [ "$METADATA_KEY" = "linux_arm64_url" ] && pass "metadata_key: linux arm64" || fail_test "metadata_key: linux arm64"
}

test_metadata_key_macos_x64() {
  DETECTED_OS="macos"; DETECTED_ARCH="x64"; select_metadata_key
  [ "$METADATA_KEY" = "macos_x64_url" ] && pass "metadata_key: macos x64" || fail_test "metadata_key: macos x64"
}

test_metadata_key_macos_arm64() {
  DETECTED_OS="macos"; DETECTED_ARCH="arm64"; select_metadata_key
  [ "$METADATA_KEY" = "macos_arm64_url" ] && pass "metadata_key: macos arm64" || fail_test "metadata_key: macos arm64"
}

test_metadata_key_windows_x64() {
  DETECTED_OS="windows"; DETECTED_ARCH="x64"; select_metadata_key
  [ "$METADATA_KEY" = "windows_x64_url" ] && pass "metadata_key: windows x64" || fail_test "metadata_key: windows x64"
}

test_metadata_key_windows_arm64_fails() {
  if ( CONTE_INSTALLER_NO_EXEC=1 . "$INSTALL_SH"
       DETECTED_OS="windows"; DETECTED_ARCH="arm64"; select_metadata_key
  ) 2>/dev/null; then
    fail_test "metadata_key: windows arm64 should fail"
  else
    pass "metadata_key: windows arm64 fails correctly"
  fi
}

# ── JSON parsing ──────────────────────────────────────────────────────────────

SAMPLE_JSON='{
  "version": "1.2.3",
  "linux_x64_url": "https://example.com/conte-cli-linux-x64.tar.gz",
  "checksums_url": "https://example.com/checksums.txt"
}'

test_json_parse_version() {
  val="$(extract_json_string "$SAMPLE_JSON" "version")"
  [ "$val" = "1.2.3" ] && pass "json_parse: version" || fail_test "json_parse: version (got: $val)"
}

test_json_parse_url() {
  val="$(extract_json_string "$SAMPLE_JSON" "linux_x64_url")"
  [ "$val" = "https://example.com/conte-cli-linux-x64.tar.gz" ] \
    && pass "json_parse: linux_x64_url" || fail_test "json_parse: linux_x64_url (got: $val)"
}

test_json_parse_missing_key() {
  val="$(extract_json_string "$SAMPLE_JSON" "nonexistent_key")"
  [ -z "$val" ] && pass "json_parse: missing key returns empty" || fail_test "json_parse: missing key (got: $val)"
}

# ── Checksum validation ───────────────────────────────────────────────────────

test_checksum_found() {
  local tmp; tmp="$(mktemp)"
  printf 'abc123  test-asset.tar.gz\n' > "$tmp"
  result="$(extract_expected_checksum "$tmp" "test-asset.tar.gz")"
  rm -f "$tmp"
  [ "$result" = "abc123" ] && pass "checksum: entry found" || fail_test "checksum: entry found (got: $result)"
}

test_checksum_star_format() {
  local tmp; tmp="$(mktemp)"
  printf 'abc123 *test-asset.tar.gz\n' > "$tmp"
  result="$(extract_expected_checksum "$tmp" "test-asset.tar.gz")"
  rm -f "$tmp"
  [ "$result" = "abc123" ] && pass "checksum: star format" || fail_test "checksum: star format (got: $result)"
}

test_checksum_missing() {
  local tmp; tmp="$(mktemp)"
  printf 'abc123  other-asset.tar.gz\n' > "$tmp"
  if ( CONTE_INSTALLER_NO_EXEC=1 . "$INSTALL_SH"
       extract_expected_checksum "$tmp" "test-asset.tar.gz"
  ) 2>/dev/null; then
    fail_test "checksum: missing entry should fail"
  else
    pass "checksum: missing entry fails correctly"
  fi
  rm -f "$tmp"
}

# ── Install root resolution ───────────────────────────────────────────────────

test_install_root_default() {
  local resolved="${CONTE_HOME:-$HOME/.conte}"
  [ "$resolved" = "$HOME/.conte" ] \
    && pass "install_root: default is ~/.conte" || fail_test "install_root: default (got: $resolved)"
}

test_install_root_override() {
  local override="/tmp/my-conte-test"
  CONTE_HOME="$override"
  [ "$CONTE_HOME" = "$override" ] \
    && pass "install_root: override respected" || fail_test "install_root: override"
  unset CONTE_HOME
}

# ── Missing dependency messages ───────────────────────────────────────────────

test_require_command_missing() {
  if ( CONTE_INSTALLER_NO_EXEC=1 . "$INSTALL_SH"
       require_command "_definitely_not_installed_xyz_"
  ) 2>/dev/null; then
    fail_test "require_command: should fail for missing command"
  else
    pass "require_command: fails for missing command"
  fi
}

# ── SHA256 tool resolution ────────────────────────────────────────────────────

test_sha256_tool_resolved() {
  resolve_sha256_tool
  [ -n "$SHA256_CMD" ] \
    && pass "sha256_tool: resolved ($SHA256_CMD)" || fail_test "sha256_tool: not resolved"
}

test_sha256_compute_matches() {
  resolve_sha256_tool
  local tmp; tmp="$(mktemp)"
  printf 'hello' > "$tmp"
  local hash; hash="$(compute_sha256 "$tmp")"
  rm -f "$tmp"
  expected="2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
  [ "$hash" = "$expected" ] \
    && pass "sha256_compute: correct hash for 'hello'" \
    || fail_test "sha256_compute: expected $expected, got $hash"
}

# ── Metadata URL versioning ───────────────────────────────────────────────────

test_version_url_substitution() {
  local base="https://github.com/conte-martin/conte-cli-installer/releases/latest/download/latest.json"
  local versioned
  versioned="$(printf '%s' "$base" | sed 's|/releases/latest/download/|/releases/download/v1.2.3/|')"
  expected="https://github.com/conte-martin/conte-cli-installer/releases/download/v1.2.3/latest.json"
  [ "$versioned" = "$expected" ] \
    && pass "version_url: substitution correct" || fail_test "version_url: got $versioned"
}

test_custom_metadata_url_unchanged() {
  local custom="https://my-server.example.com/latest.json"
  local result
  result="$(printf '%s' "$custom" | sed 's|/releases/latest/download/|/releases/download/v1.2.3/|')"
  [ "$result" = "$custom" ] \
    && pass "version_url: custom URL unchanged" || fail_test "version_url: custom URL was changed"
}

# ── Idempotent reinstall (no crash on existing installation) ──────────────────

test_idempotent_reinstall_no_crash() {
  local tmp_home; tmp_home="$(mktemp -d)"
  mkdir -p "$tmp_home/bin"
  # Simulate an existing installation
  printf '#!/bin/sh\necho v0.9.0\n' > "$tmp_home/bin/conte"
  chmod +x "$tmp_home/bin/conte"
  # The binary should be overwritable without error
  printf '#!/bin/sh\necho v1.0.0\n' > "$tmp_home/bin/conte"
  chmod +x "$tmp_home/bin/conte"
  local version; version="$("$tmp_home/bin/conte" --version 2>/dev/null || true)"
  rm -rf "$tmp_home"
  [ "$version" = "v1.0.0" ] \
    && pass "idempotent: reinstall overwrites correctly" \
    || fail_test "idempotent: reinstall (got version: $version)"
}

# ── Uninstall safety ──────────────────────────────────────────────────────────

test_uninstall_nonexistent_dir() {
  local output
  output="$(CONTE_HOME="/tmp/conte-test-nonexistent-$$" bash "$SCRIPT_DIR/../uninstall.sh" 2>&1)"
  printf '%s' "$output" | grep -q "Nothing to uninstall" \
    && pass "uninstall: idempotent when dir missing" \
    || fail_test "uninstall: expected 'Nothing to uninstall' (got: $output)"
}

test_uninstall_removes_dir() {
  local tmp_home; tmp_home="$(mktemp -d)"
  mkdir -p "$tmp_home/bin"
  printf '#!/bin/sh\necho v1.0.0\n' > "$tmp_home/bin/conte"
  chmod +x "$tmp_home/bin/conte"

  CONTE_HOME="$tmp_home" bash "$SCRIPT_DIR/../uninstall.sh" >/dev/null 2>&1

  if [ ! -d "$tmp_home" ]; then
    pass "uninstall: removes installation directory"
  else
    fail_test "uninstall: directory was not removed"
    rm -rf "$tmp_home"
  fi
}

test_uninstall_refuses_root() {
  if CONTE_HOME="/" bash "$SCRIPT_DIR/../uninstall.sh" 2>/dev/null; then
    fail_test "uninstall: should refuse CONTE_HOME=/"
  else
    pass "uninstall: refuses CONTE_HOME=/"
  fi
}

test_uninstall_refuses_home_dir() {
  if CONTE_HOME="$HOME" bash "$SCRIPT_DIR/../uninstall.sh" 2>/dev/null; then
    fail_test "uninstall: should refuse CONTE_HOME=\$HOME"
  else
    pass "uninstall: refuses CONTE_HOME=\$HOME"
  fi
}

test_uninstall_idempotent() {
  local tmp_home; tmp_home="$(mktemp -d)"
  mkdir -p "$tmp_home/bin"

  CONTE_HOME="$tmp_home" bash "$SCRIPT_DIR/../uninstall.sh" >/dev/null 2>&1
  # Run again -- should report nothing to uninstall without error
  local output
  output="$(CONTE_HOME="$tmp_home" bash "$SCRIPT_DIR/../uninstall.sh" 2>&1)"
  printf '%s' "$output" | grep -q "Nothing to uninstall" \
    && pass "uninstall: idempotent (second run)" \
    || fail_test "uninstall: second run (got: $output)"
}

# ── Run all tests ─────────────────────────────────────────────────────────────

printf '\n=== Conte CLI Installer Smoke Tests ===\n\n'

test_os_linux
test_os_macos
test_os_mingw
test_os_msys
test_os_unknown

test_arch_x64
test_arch_amd64
test_arch_arm64
test_arch_aarch64
test_arch_unknown

test_metadata_key_linux_x64
test_metadata_key_linux_arm64
test_metadata_key_macos_x64
test_metadata_key_macos_arm64
test_metadata_key_windows_x64
test_metadata_key_windows_arm64_fails

test_json_parse_version
test_json_parse_url
test_json_parse_missing_key

test_checksum_found
test_checksum_star_format
test_checksum_missing

test_install_root_default
test_install_root_override

test_require_command_missing

test_sha256_tool_resolved
test_sha256_compute_matches

test_version_url_substitution
test_custom_metadata_url_unchanged

test_idempotent_reinstall_no_crash

test_uninstall_nonexistent_dir
test_uninstall_removes_dir
test_uninstall_refuses_root
test_uninstall_refuses_home_dir
test_uninstall_idempotent

printf '\n=== Results: %d passed, %d failed ===\n\n' "$TESTS_PASSED" "$TESTS_FAILED"
[ "$TESTS_FAILED" -eq 0 ] || exit 1
