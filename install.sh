#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# ardu bootstrap installer
# Repo: https://github.com/kenguru33/arduino-build-tools
#
# - Verifies required tools
# - Clones or updates the repo
# - Runs setup via bash (no +x dependency)
#
# Installs into:
#   ~/.local/share/arduino-build-tools
#   ~/.local/bin/ardu
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
# Required tools (HARD GATE)
# ------------------------------------------------------------
REQUIRED_TOOLS=(
  bash
  git
)

missing=()
for tool in "${REQUIRED_TOOLS[@]}"; do
  command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done

if [[ "${#missing[@]}" -gt 0 ]]; then
  echo >&2
  echo "${RED}❌ Installation aborted: missing required tools:${RESET}" >&2
  for t in "${missing[@]}"; do
    echo "  - $t" >&2
  done
  exit 1
fi

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
# Locate setup script
# ------------------------------------------------------------
SETUP_SCRIPT="$CLONE_DIR/tools/ardu-setup.sh"
[[ -f "$SETUP_SCRIPT" ]] || die "Setup script not found: tools/ardu-setup.sh"

# ------------------------------------------------------------
# Run setup (explicit bash)
# ------------------------------------------------------------
log "Running setup"
bash "$SETUP_SCRIPT"

echo
echo "${GREEN}✅ Installation complete${RESET}"
echo "Run: ardu help"
