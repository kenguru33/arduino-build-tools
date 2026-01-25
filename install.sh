#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# ardu bootstrap installer
# Repo: https://github.com/kenguru33/arduino-build-tools
#
# Installs into:
#   ~/.local/share/arduino-build-tools
#   ~/.local/bin/ardu
# ============================================================

REPO_URL="https://github.com/kenguru33/arduino-build-tools.git"
REPO_NAME="arduino-build-tools"

INSTALL_BASE="$HOME/.local/share"
CLONE_DIR="$INSTALL_BASE/$REPO_NAME"

log() { echo "📦 $*"; }
die() {
  echo "❌ $*" >&2
  exit 1
}

# ------------------------------------------------------------
# Requirements
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
# Run setup
# ------------------------------------------------------------
SETUP_SCRIPT="$CLONE_DIR/tools/ardu-setup.sh"
[[ -x "$SETUP_SCRIPT" ]] || die "Setup script not found or not executable"

log "Running setup"
"$SETUP_SCRIPT"

log "Installation complete"
log "Run: ardu help"
