#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Arduino Project Initializer (FINAL, AUTHORITATIVE)
# ============================================================

PROJECT_NAME="${1:-arduino-project}"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
log() { echo "📦 $*"; }
die() {
  echo "❌ $*" >&2
  exit 1
}
need() { command -v "$1" >/dev/null || die "Missing dependency: $1"; }

# ------------------------------------------------------------
# Dependencies
# ------------------------------------------------------------
need git
need make
need bear
need mkdir
need cat
need rm
need cp

# ------------------------------------------------------------
# Create structure
# ------------------------------------------------------------
log "Creating project: $PROJECT_NAME"
mkdir -p "$PROJECT_NAME"/{src,libs,tools,core,.ccdb}

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
# Top-level Makefile (FIXED CCDB)
# ------------------------------------------------------------
cat >"$PROJECT_NAME/Makefile" <<'EOF'
# ------------------------------------------------------------
# Board / Upload
# ------------------------------------------------------------
MCU     = atmega328p
F_CPU   = 16000000UL
PORT    = /dev/ttyACM0
BAUD    = 115200

# ------------------------------------------------------------
# Toolchain
# ------------------------------------------------------------
CC      = avr-gcc
CXX     = avr-g++
OBJCOPY = avr-objcopy

# ------------------------------------------------------------
# Arduino core
# ------------------------------------------------------------
CORE_DIR = core
CORE_LIB = $(CORE_DIR)/build/core.a

# ------------------------------------------------------------
# Arduino architecture
# ------------------------------------------------------------
ARDUINO_ARCH = avr

# ------------------------------------------------------------
# Arduino-style libraries
# ------------------------------------------------------------
LIBS     =
LIB_DIR  = libs

LIB_SRC := $(foreach L,$(LIBS), \
  $(wildcard $(LIB_DIR)/$(L)/src/$(ARDUINO_ARCH)/*.cpp) \
  $(wildcard $(LIB_DIR)/$(L)/src/*.cpp))

LIB_INC := $(foreach L,$(LIBS), \
  -I$(LIB_DIR)/$(L)/src \
  -I$(LIB_DIR)/$(L)/src/$(ARDUINO_ARCH))

# ------------------------------------------------------------
# Compiler flags
# ------------------------------------------------------------
CFLAGS = -mmcu=$(MCU) -DF_CPU=$(F_CPU) -Os \
  -Wall -ffunction-sections -fdata-sections \
  -DARDUINO=10819 \
  -DARDUINO_ARCH_AVR \
  -DARDUINO_AVR_UNO \
  -I$(CORE_DIR)/cores/arduino \
  -I$(CORE_DIR)/variants/standard \
  $(LIB_INC)

CXXFLAGS = $(CFLAGS) -fno-exceptions -fno-rtti
LDFLAGS  = -Wl,--gc-sections

# ------------------------------------------------------------
# Sources
# ------------------------------------------------------------
SRC := src/main.cpp $(LIB_SRC)
OBJ := $(SRC:%.cpp=build/%.o)

# ------------------------------------------------------------
# Targets
# ------------------------------------------------------------
all: build/firmware.hex

# Build Arduino core on demand
$(CORE_LIB):
	$(MAKE) -C $(CORE_DIR)

build/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

build/firmware.elf: $(OBJ) $(CORE_LIB)
	$(CXX) $(CXXFLAGS) $(OBJ) $(CORE_LIB) -o $@ $(LDFLAGS)

build/firmware.hex: build/firmware.elf
	$(OBJCOPY) -O ihex $< $@

# ------------------------------------------------------------
# ALWAYS-FORCED compile_commands.json (STUB-BASED)
# ------------------------------------------------------------
.PHONY: ccdb

ccdb:
	rm -f compile_commands.json
	rm -f .ccdb/stub.o
	bear -- $(CXX) $(CXXFLAGS) -c .ccdb/stub.cpp -o .ccdb/stub.o

flash: build/firmware.hex
	avrdude -p m328p -c arduino -P $(PORT) -b $(BAUD) \
		-U flash:w:$<

clean:
	rm -rf build .ccdb
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

# ------------------------------------------------------------
# Stub file for clangd / ccdb
# ------------------------------------------------------------
cat >"$PROJECT_NAME/.ccdb/stub.cpp" <<'EOF'
#include <Arduino.h>
int main() { return 0; }
EOF

# ------------------------------------------------------------
# Generate compile_commands.json (GUARANTEED NON-EMPTY)
# ------------------------------------------------------------
log "Generating compile_commands.json (forced stub)"
cd "$PROJECT_NAME"
make ccdb >/dev/null

log "Project initialized successfully"
log "cd $PROJECT_NAME"
log "make        # build firmware"
log "make ccdb   # refresh autocomplete anytime"
log "✅ Done"
