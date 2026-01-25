#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# ardu bootstrap installer
# Repo: https://github.com/kenguru33/arduino-build-tools
#
# - Verifies minimal requirements
# - Clones or updates the repo
# - Auto-detects and runs setup script
#
# Installs into:
#   ~/.local/share/arduino-build-tools
# ============================================================

REPO_URL="https://github.com/kenguru33/arduino-build-tools.git"
REPO_NAME="arduino-build-tools"

INSTALL_BASE="$HOME/.local/share"
CLONE_DIR="$INSTALL_BASE/$REPO_NAME"

RED=$'\e[31m'
GREEN=$'\e[32m'
RESET=$'\e[0m'

log() { echo "📦 $*"; }
die() {
  echo "${RED}❌ $*${RESET}" >&2
  exit 1
}

# ------------------------------------------------------------
# Minimal required tools for bootstrap
# ------------------------------------------------------------
for tool in bash git; do
  command -v "$tool" >/dev/null || die "Required tool missing: $tool"
done

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
# Locate setup script (AUTHORITATIVE)
# ------------------------------------------------------------
SETUP_SCRIPT=""

for candidate in \
  "$CLONE_DIR/tools/ardu-setup.sh" \
  "$CLONE_DIR/tools/setup.sh" \
  "$CLONE_DIR/tools/install.sh"; do
  if [[ -f "$candidate" ]]; then
    SETUP_SCRIPT="$candidate"
    break
  fi
done

[[ -n "$SETUP_SCRIPT" ]] || die "No setup script found in tools/"

log "Running setup: $(basename "$SETUP_SCRIPT")"
bash "$SETUP_SCRIPT"

echo
echo "${GREEN}✅ Installation complete${RESET}"
echo "Run: ardu help"
