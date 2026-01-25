#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# ardu setup script
# Installs ardu CLI and tools into user space
#
# Target:
#   ~/.local/share/ardu-tools
#   ~/.local/bin/ardu
# ============================================================

TOOLS_SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_DIR="$HOME/.local/share/ardu-tools"
BIN_DIR="$HOME/.local/bin"

ARDU_BIN="$BIN_DIR/ardu"

log() { echo "📦 $*"; }
die() {
  echo "❌ $*" >&2
  exit 1
}

# ------------------------------------------------------------
# Preconditions
# ------------------------------------------------------------
[[ -d "$TOOLS_SRC_DIR" ]] || die "tools directory not found"
[[ -f "$TOOLS_SRC_DIR/ardu" ]] || die "ardu entry script not found"

# ------------------------------------------------------------
# Create directories
# ------------------------------------------------------------
log "Creating install directories"
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# ------------------------------------------------------------
# Copy tools
# ------------------------------------------------------------
log "Installing tools to $INSTALL_DIR"

cp -f "$TOOLS_SRC_DIR/ardu" "$INSTALL_DIR/"
cp -f "$TOOLS_SRC_DIR/arduino-project-init.sh" "$INSTALL_DIR/"
cp -f "$TOOLS_SRC_DIR/arduino-lib.sh" "$INSTALL_DIR/"
cp -f "$TOOLS_SRC_DIR/arduino-doctor.sh" "$INSTALL_DIR/"

chmod +x "$INSTALL_DIR/"*

# ------------------------------------------------------------
# Create launcher in ~/.local/bin
# ------------------------------------------------------------
log "Creating launcher: $ARDU_BIN"

cat >"$ARDU_BIN" <<EOF
#!/usr/bin/env bash
exec "$INSTALL_DIR/ardu" "\$@"
EOF

chmod +x "$ARDU_BIN"

# ------------------------------------------------------------
# PATH hint
# ------------------------------------------------------------
if ! command -v ardu >/dev/null 2>&1; then
  echo
  echo "⚠️  ~/.local/bin is not on your PATH"
  echo "Add this to your shell config:"
  echo
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo
fi

log "ardu installed successfully"
log "Run: ardu help"
log "✅ Done"
