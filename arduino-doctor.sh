#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Arduino Project Doctor
# - Works from ANY directory
# - Uses explicit project marker (.arduino-project)
# - Walks up directories to find project root
# - Silent unless warnings/errors
# - ONE success line if everything is OK
# ============================================================

RED=$'\e[31m'
YELLOW=$'\e[33m'
GREEN=$'\e[32m'
RESET=$'\e[0m'

error_count=0
warn_count=0

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
err() {
  echo "${RED}✖${RESET} $*" >&2
  error_count=$((error_count + 1))
}

warn() {
  echo "${YELLOW}⚠${RESET} $*" >&2
  warn_count=$((warn_count + 1))
}

need() {
  command -v "$1" >/dev/null || err "Required tool missing: $1"
}

# ------------------------------------------------------------
# Required tools (FAIL FAST)
# ------------------------------------------------------------
need make
need avr-gcc
need avr-g++
need avr-objcopy
need ar
need git
need bear
need jq
need arduino-cli
need avrdude
need clangd

if [[ "$error_count" -gt 0 ]]; then
  echo >&2
  echo "${RED}Doctor aborted: required tools missing${RESET}" >&2
  exit 1
fi

# ------------------------------------------------------------
# Project root detection (marker-based, walk up)
# ------------------------------------------------------------
find_project_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.arduino-project" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

PROJECT_ROOT="$(find_project_root || true)"

# ------------------------------------------------------------
# Not in project → warn ONCE and exit cleanly
# ------------------------------------------------------------
if [[ -z "$PROJECT_ROOT" ]]; then
  warn "Not inside an Arduino project directory"
  exit 0
fi

cd "$PROJECT_ROOT"

# ------------------------------------------------------------
# Project structure
# ------------------------------------------------------------
[[ -f Makefile ]] || err "Makefile missing"
[[ -d core ]] || err "core/ directory missing"
[[ -f core/Makefile ]] || err "core/Makefile missing"
[[ -d src ]] || err "src/ directory missing"
[[ -d .ccdb ]] || err ".ccdb directory missing"
[[ -f .ccdb/stub.cpp ]] || err ".ccdb/stub.cpp missing"
[[ -d libs ]] || warn "libs/ directory missing (no libraries installed)"

# ------------------------------------------------------------
# Makefile sanity (TAB-sensitive)
# ------------------------------------------------------------
if grep -nP '^[ ]+\t|^\t[ ]+' Makefile >/dev/null; then
  err "Makefile contains mixed TAB/space indentation (will break make)"
fi

# ------------------------------------------------------------
# LIBS consistency
# ------------------------------------------------------------
if [[ -d libs ]]; then
  LIBS_LINE=$(grep -E '^[[:space:]]*LIBS[[:space:]]*=' Makefile | sed 's/^[^=]*=//')
  for lib in $LIBS_LINE; do
    [[ -d "libs/$lib" ]] || err "Library '$lib' listed in Makefile but missing in libs/"
  done
fi

# ------------------------------------------------------------
# Arduino core
# ------------------------------------------------------------
[[ -f core/build/core.a ]] || warn "Arduino core not built (run: make)"

# ------------------------------------------------------------
# compile_commands.json
# ------------------------------------------------------------
if [[ -f compile_commands.json ]]; then
  count=$(jq length compile_commands.json 2>/dev/null || echo 0)
  [[ "$count" -gt 0 ]] || err "compile_commands.json exists but is empty"
else
  warn "compile_commands.json missing (run: make ccdb)"
fi

# ------------------------------------------------------------
# Final result
# ------------------------------------------------------------
if [[ "$error_count" -gt 0 ]]; then
  echo >&2
  echo "${RED}Doctor found $error_count error(s)${RESET}" >&2
  exit 1
fi

if [[ "$warn_count" -eq 0 ]]; then
  echo "${GREEN}🩺 Doctor: all checks passed${RESET}"
fi

exit 0
