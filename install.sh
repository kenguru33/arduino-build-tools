#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# ardu bootstrap installer
# Repo: https://github.com/kenguru33/arduino-build-tools
#
# - Clones or updates the repo
# - Runs ardu-setup.sh from repo root
#
# Installs into:
#   ~/.local/share/arduino-build-tools
# ============================================================

REPO_URL="https://github.com/kenguru33/arduino-build-tools.git"
INSTALL_BASE="$HOME/.local/share"
CLONE_DIR="$INSTALL_BASE/arduino-build-tools"

log() { echo "📦 $*"; }
die() {
  echo "❌ $*" >&2
  exit 1
}

# ------------------------------------------------------------
# Minimal bootstrap requirements
# ------------------------------------------------------------
command -v git >/dev/null || die "git is required"
command -v bash >/dev/null || die "bash is required"

# ------------------------------------------------------------
# Clone or update repo
# ------------------------------------------------------------
log "Installing Arduino build tools"
mkdir -p "$INSTALL_BASE"

if [[ -d "$CLONE_DIR/.git" ]]; then
  log "Updating existing installation"
  git -C "$CLONE_DIR" pull --ff-only
else
  log "Cloning repository"
  git clone "$REPO_URL" "$CLONE_DIR"
fi

# ------------------------------------------------------------
# Run setup (CORRECT PATH)
# ------------------------------------------------------------
SETUP_SCRIPT="$CLONE_DIR/ardu-setup.sh"
[[ -f "$SETUP_SCRIPT" ]] || die "Setup script not found: $SETUP_SCRIPT"

log "Running setup"
bash "$SETUP_SCRIPT"

echo
echo "✅ Installation complete"
echo "Run: ardu help"
