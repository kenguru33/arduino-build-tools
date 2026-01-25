#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# ardu bootstrap installer
# Repo: https://github.com/kenguru33/arduino-build-tools
#
# - Verifies required tools
# - Clones or updates the repo
# - Runs user-space setup
#
# Target install:
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
  make
  avr-gcc
  avr-g++
  avr-objcopy
  ar
  bear
  jq
  arduino-cli
  avrdude
  clangd
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
  echo >&2
  echo "Install the missing tools, then re-run the installer." >&2
  exit 1
fi

log "All required tools found"

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

echo
echo "${GREEN}✅ Installation complete${RESET}"
echo "Run: ardu help"
