#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Arduino Library Manager (FINAL, MAKEFILE-SAFE)
# ============================================================

LIB_DIR="libs"
MAKEFILE="Makefile"

log() { echo "📦 $*"; }
warn() { echo "⚠️  $*" >&2; }
die() {
  echo "❌ $*" >&2
  exit 1
}
need() { command -v "$1" >/dev/null || die "Missing dependency: $1"; }

need arduino-cli
need jq
need cp
need rm
need mkdir
need make
need bear

[[ $# -ne 2 ]] && die "Usage: $0 <install|remove> <LibraryName>"

CMD="$1"
LIB="$2"

[[ "$CMD" == "install" || "$CMD" == "remove" ]] || die "Command must be install or remove"
[[ -f "$MAKEFILE" ]] || die "Makefile not found"
[[ -f ".ccdb/stub.cpp" ]] || die ".ccdb/stub.cpp missing"

arduino-cli config init >/dev/null 2>&1 || true
arduino-cli lib update-index >/dev/null

# ------------------------------------------------------------
# Read current LIBS line safely
# ------------------------------------------------------------
read_libs() {
  grep -E '^[[:space:]]*LIBS[[:space:]]*=' "$MAKEFILE" | sed 's/^[^=]*=//'
}

write_libs() {
  local new="$1"
  awk -v libs="$new" '
    /^[[:space:]]*LIBS[[:space:]]*=/ {
      print "LIBS = " libs
      next
    }
    { print }
  ' "$MAKEFILE" >"$MAKEFILE.tmp"
  mv "$MAKEFILE.tmp" "$MAKEFILE"
}

CURRENT_LIBS="$(read_libs | tr -s ' ')"

# ============================================================
# INSTALL
# ============================================================
if [[ "$CMD" == "install" ]]; then
  log "Installing $LIB"
  arduino-cli lib install "$LIB"

  USER_DIR="$(arduino-cli config dump --json | jq -r '.directories.user // empty')"
  [[ -z "$USER_DIR" ]] && USER_DIR="$HOME/Arduino"

  SRC="$USER_DIR/libraries/$LIB"
  [[ -d "$SRC" ]] || die "Library not found: $LIB"

  rm -rf "$LIB_DIR/$LIB"
  mkdir -p "$LIB_DIR"
  cp -a "$SRC" "$LIB_DIR/$LIB"

  if ! grep -qw "$LIB" <<<"$CURRENT_LIBS"; then
    write_libs "$CURRENT_LIBS $LIB"
  else
    log "LIBS already contains $LIB"
  fi
fi

# ============================================================
# REMOVE
# ============================================================
if [[ "$CMD" == "remove" ]]; then
  log "Removing $LIB"
  rm -rf "$LIB_DIR/$LIB"

  NEW_LIBS="$(sed "s/\b$LIB\b//g" <<<"$CURRENT_LIBS" | tr -s ' ' | sed 's/^ //; s/ $//')"
  write_libs "$NEW_LIBS"
fi

# ============================================================
# Refresh compile_commands.json (FORCED, SAFE)
# ============================================================
log "Refreshing compile_commands.json"
make ccdb

log "✅ Done"
