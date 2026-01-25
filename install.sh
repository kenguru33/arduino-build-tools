#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# ardu bootstrap installer
# - clones repo
# - runs setup
# - installs into ~/.local
# ============================================================

REPO_URL="https://github.com/YOUR_ORG/ardu-tools.git"
REPO_NAME="ardu-tools"

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
log "Installing ardu-tools"

mkdir -p "$INSTALL_BASE"

if [[ -d "$CLONE_DIR/.git" ]]; then
  log "Updating existing repo"
  git -C "$CLONE_DIR" pull --ff-only
else
  log "Cloning repo"
  git clone "$REPO_URL" "$CLONE_DIR"
fi

# ------------------------------------------------------------
# Run setup
# ------------------------------------------------------------
SETUP_SCRIPT="$CLONE_DIR/tools/ardu-setup.sh"
[[ -x "$SETUP_SCRIPT" ]] || die "Setup script not found"

log "Running setup"
"$SETUP_SCRIPT"

log "Installation complete"
log "Run: ardu help"
