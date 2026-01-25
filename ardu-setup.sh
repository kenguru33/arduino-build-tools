#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# ardu setup script
# - Registers existing ardu tools in user space
# - DOES NOT copy or move files
#
# Expected layout:
#   ~/.local/share/ardu-tools/
#     ├── ardu
#     ├── arduino-project-init.sh
#     ├── arduino-lib.sh
#     └── arduino-doctor.sh
#
# Installs:
#   ~/.local/bin/ardu  (launcher only)
# ============================================================

TOOLS_DIR="$HOME/.local/share/ardu-tools"
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
[[ -d "$TOOLS_DIR" ]] || die "Tools directory not found: $TOOLS_DIR"
[[ -f "$TOOLS_DIR/ardu" ]] || die "ardu entry script not found in $TOOLS_DIR"

# Ensure all required scripts exist
for f in ardu arduino-project-init.sh arduino-lib.sh arduino-doctor.sh; do
  [[ -f "$TOOLS_DIR/$f" ]] || die "Missing required tool: $TOOLS_DIR/$f"
done

# ------------------------------------------------------------
# Create bin dir
# ------------------------------------------------------------
mkdir -p "$BIN_DIR"

# ------------------------------------------------------------
# Create launcher (no copying)
# ------------------------------------------------------------
log "Creating launcher: $ARDU_BIN"

cat >"$ARDU_BIN" <<EOF
#!/usr/bin/env bash
exec "$TOOLS_DIR/ardu" "\$@"
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

log "ardu registered successfully"
log "Run: ardu help"
log "✅ Done"
