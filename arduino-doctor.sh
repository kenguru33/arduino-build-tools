#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Arduino Project Doctor
# - Silent unless there are warnings/errors
# - Shows ONE success line if everything is OK
# - Read-only diagnostics
# ============================================================

RED=$'\e[31m'
YELLOW=$'\e[33m'
GREEN=$'\e[32m'
RESET=$'\e[0m'

error_count=0
warn_count=0

err() {
  echo "${RED}✖${RESET} $*" >&2
  error_count=$((error_count + 1))
}

warn() {
  echo "${YELLOW}⚠${RESET} $*" >&2
  warn_count=$((warn_count + 1))
}

need_required() {
  command -v "$1" >/dev/null || err "Required tool missing: $1"
}

need_optional() {
  command -v "$1" >/dev/null || warn "Optional tool missing: $1"
}

# ------------------------------------------------------------
# Required tools (project cannot function without these)
# ------------------------------------------------------------
need_required make
need_required avr-gcc
need_required avr-g++
need_required ar
need_required objcopy || true
need_required avr-objcopy
need_required git

# ------------------------------------------------------------
# Optional but recommended tools
# ------------------------------------------------------------
need_optional bear        # compile_commands.json
need_optional jq          # doctor + scripts
need_optional arduino-cli # library management
need_optional avrdude     # flashing

# ------------------------------------------------------------
# Project structure
# ------------------------------------------------------------
[[ -f Makefile ]] || err "Makefile missing"
[[ -d core ]] || err "core/ directory missing"
[[ -f core/Makefile ]] || err "core/Makefile missing"
[[ -d src ]] || err "src/ directory missing"
[[ -d libs ]] || warn "libs/ directory missing (no libraries installed)"
[[ -d .ccdb ]] || err ".ccdb directory missing"
[[ -f .ccdb/stub.cpp ]] || err ".ccdb/stub.cpp missing"

# ------------------------------------------------------------
# Makefile sanity (TAB-sensitive)
# ------------------------------------------------------------
if [[ -f Makefile ]]; then
  if grep -nP '^[ ]+\t|^\t[ ]+' Makefile >/dev/null; then
    err "Makefile contains mixed TAB/space indentation (will break make)"
  fi
fi

# ------------------------------------------------------------
# LIBS consistency
# ------------------------------------------------------------
if [[ -f Makefile && -d libs ]]; then
  LIBS_LINE=$(grep -E '^[[:space:]]*LIBS[[:space:]]*=' Makefile | sed 's/^[^=]*=//')
  for lib in $LIBS_LINE; do
    [[ -d "libs/$lib" ]] || err "Library '$lib' listed in Makefile but missing in libs/"
  done
fi

# ------------------------------------------------------------
# Arduino core
# ------------------------------------------------------------
if [[ -d core && -f core/Makefile ]]; then
  [[ -f core/build/core.a ]] || warn "Arduino core not built (run: make)"
fi

# ------------------------------------------------------------
# compile_commands.json
# ------------------------------------------------------------
if [[ -f compile_commands.json ]]; then
  if command -v jq >/dev/null; then
    count=$(jq length compile_commands.json 2>/dev/null || echo 0)
    [[ "$count" -gt 0 ]] || err "compile_commands.json exists but is empty"
  fi
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
