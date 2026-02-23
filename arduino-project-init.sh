#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Arduino Project Initializer (cleaned: no clangd/ccdb, no stub)
# ============================================================

PROJECT_NAME="${1:-arduino-project}"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
log() { echo "📦 $*"; }
die() { echo "❌ $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Missing dependency: $1"; }

# ------------------------------------------------------------
# Dependencies
# ------------------------------------------------------------
need git
need make
need mkdir
need cat
need rm
need cp

# ------------------------------------------------------------
# Create structure
# ------------------------------------------------------------
log "Creating project: $PROJECT_NAME"
mkdir -p "$PROJECT_NAME"/{src,libs,tools,core}

# ------------------------------------------------------------
# Project marker
# ------------------------------------------------------------
touch "$PROJECT_NAME/.arduino-project"

# ------------------------------------------------------------
# Copy Wokwi/diagram files (prefer tool install dir)
# ------------------------------------------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

for f in diagram.json wokwi.toml; do
  src=""
  if [[ -f "$SCRIPT_DIR/$f" ]]; then
    src="$SCRIPT_DIR/$f"
  elif [[ -f "$f" ]]; then
    # Fallback for running the script from the repo root.
    src="$f"
  fi

  if [[ -n "$src" ]]; then
    cp "$src" "$PROJECT_NAME/$f"
    log "Added $f"
  else
    log "Skipping $f (not found)"
  fi
done

# ------------------------------------------------------------
# Top-level Makefile
# ------------------------------------------------------------
cat >"$PROJECT_NAME/Makefile" <<'EOF'
# ============================================================
# Project
# ============================================================
TARGET    = firmware
BUILD_DIR = build

# ============================================================
# Board
# ============================================================
MCU   = atmega328p
F_CPU = 16000000UL
PORT  = /dev/ttyACM0
BAUD  = 115200

# ============================================================
# Toolchain
# ============================================================
CC      = avr-gcc
CXX     = avr-g++
OBJCOPY = avr-objcopy
SIZE    = avr-size

# ============================================================
# Arduino core
# ============================================================
CORE_DIR       = core
CORE_BUILD_DIR = $(CORE_DIR)/build
CORE_LIB       = $(CORE_BUILD_DIR)/core.a

# ============================================================
# Flags
# ============================================================
COMMON_FLAGS = -mmcu=$(MCU) -DF_CPU=$(F_CPU) -Os \
               -Wall -ffunction-sections -fdata-sections \
               -DARDUINO=10819 \
               -DARDUINO_ARCH_AVR \
               -DARDUINO_AVR_UNO \
               -I$(CORE_DIR)/cores/arduino \
               -I$(CORE_DIR)/variants/standard

CXXFLAGS = $(COMMON_FLAGS) -fno-exceptions -fno-rtti
LDFLAGS  = -Wl,--gc-sections

# ============================================================
# Sources
# ============================================================
SRC_CPP = src/main.cpp
OBJ     = $(BUILD_DIR)/main.o

# ============================================================
# Default
# ============================================================
all: $(BUILD_DIR)/$(TARGET).hex

# ============================================================
# Force avr-ar / avr-ranlib (CRITICAL ON macOS)
# ============================================================
TOOLS_DIR = .tools/bin

$(TOOLS_DIR)/ar:
	@mkdir -p $(TOOLS_DIR)
	@printf '%s\n' '#!/usr/bin/env sh' 'exec avr-ar "$$@"' > $@
	@chmod +x $@

$(TOOLS_DIR)/ranlib:
	@mkdir -p $(TOOLS_DIR)
	@printf '%s\n' '#!/usr/bin/env sh' 'exec avr-ranlib "$$@"' > $@
	@chmod +x $@

$(CORE_LIB): $(TOOLS_DIR)/ar $(TOOLS_DIR)/ranlib
	rm -rf $(CORE_BUILD_DIR)
	PATH="$(abspath $(TOOLS_DIR)):$$PATH" \
	$(MAKE) -C $(CORE_DIR) CC=$(CC) CXX=$(CXX)

# ============================================================
# Compile
# ============================================================
$(BUILD_DIR)/main.o: src/main.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# ============================================================
# Link
# ============================================================
$(BUILD_DIR)/$(TARGET).elf: $(OBJ) $(CORE_LIB)
	$(CXX) $(CXXFLAGS) \
		$(OBJ) \
		-Wl,--start-group \
		$(CORE_LIB) \
		-Wl,--end-group \
		$(LDFLAGS) \
		-o $@
	$(SIZE) $@

# ============================================================
# HEX
# ============================================================
$(BUILD_DIR)/$(TARGET).hex: $(BUILD_DIR)/$(TARGET).elf
	$(OBJCOPY) -O ihex $< $@

# ============================================================
# Flash
# ============================================================
flash: $(BUILD_DIR)/$(TARGET).hex
	avrdude -p m328p -c arduino -P $(PORT) -b $(BAUD) \
		-U flash:w:$<

# ============================================================
# Clean
# ============================================================
clean:
	rm -rf $(BUILD_DIR) $(CORE_BUILD_DIR) .tools

.PHONY: all clean flash
EOF

# ------------------------------------------------------------
# Clone Arduino AVR core
# ------------------------------------------------------------
log "Cloning Arduino AVR core"
git clone https://github.com/arduino/ArduinoCore-avr.git "$PROJECT_NAME/core"

# ------------------------------------------------------------
# Core Makefile
# ------------------------------------------------------------
cat >"$PROJECT_NAME/core/Makefile" <<'EOF'
MCU     = atmega328p
F_CPU   = 16000000UL

CC      = avr-gcc
CXX     = avr-g++

BUILD_DIR = build
CORE_LIB  = $(BUILD_DIR)/core.a

SRC := $(wildcard cores/arduino/*.c) \
       $(wildcard cores/arduino/*.cpp) \
       $(wildcard cores/arduino/*.S)

OBJ := $(SRC:%.c=$(BUILD_DIR)/%.o)
OBJ := $(OBJ:%.cpp=$(BUILD_DIR)/%.o)
OBJ := $(OBJ:%.S=$(BUILD_DIR)/%.o)

CFLAGS = -mmcu=$(MCU) -DF_CPU=$(F_CPU) -Os \
  -Wall -ffunction-sections -fdata-sections \
  -Icores/arduino -Ivariants/standard

CXXFLAGS = $(CFLAGS) -fno-exceptions -fno-rtti

all: $(CORE_LIB)

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.S
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(CORE_LIB): $(OBJ)
	ar rcs $@ $^

clean:
	rm -rf build
EOF

# ------------------------------------------------------------
# main.cpp
# ------------------------------------------------------------
cat >"$PROJECT_NAME/src/main.cpp" <<'EOF'
#include <Arduino.h>

void setup() {}
void loop() {}
EOF

log "Project initialized successfully"
log "cd $PROJECT_NAME"
log "make        # build firmware"
log "make flash  # upload to board"
log "✅ Done"