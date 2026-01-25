#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# ardu bootstrap installer
# Repo: https://github.com/kenguru33/arduino-build-tools
#
# - Clones or updates the repo
# - AUTO-DETECTS setup script under tools/
# - Runs it via bash
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
# Locate setup script dynamically (NO HARD-CODING)
# ------------------------------------------------------------
SETUP_SCRIPT=""

while IFS= read -r -d '' candidate; do
  SETUP_SCRIPT="$candidate"
  break
done < <(find "$CLONE_DIR/tools" -maxdepth 1 -type f -iname '*setup*.sh' -print0)

[[ -n "$SETUP_SCRIPT" ]] || die "No setup script found under tools/ (expected *setup*.sh)"

log "Running setup: $(basename "$SETUP_SCRIPT")"
bash "$SETUP_SCRIPT"

echo
echo "✅ Installation complete"
echo "Run: ardu help"
