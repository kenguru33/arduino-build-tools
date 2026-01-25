
# Arduino Makefile Toolchain (No Arduino IDE)

This project provides a **clean, reproducible, IDE-agnostic Arduino development setup**
based on **Makefiles**, **avr-gcc**, and **clangd** — without using the Arduino IDE.

It is designed for developers who want:
- full control over the build
- reproducible projects
- proper autocomplete and navigation
- zero hidden tooling or magic

---

## Why this exists

The Arduino IDE:
- hides the real compiler flags
- does not scale to larger projects
- makes editor integration difficult
- is not reproducible in CI or across machines

This toolchain solves that by:

- using **plain Makefiles**
- vendoring **all dependencies per project**
- generating a **real `compile_commands.json`**
- working with **Neovim, VS Code, CLion, etc.**
- remaining transparent and debuggable

If something breaks, you can see *why*.

---

## What this project gives you

After initialization, each project has:

- `Makefile` – firmware build, flashing, tooling
- `core/` – vendored Arduino AVR core
- `libs/` – vendored Arduino libraries (per project)
- `.ccdb/` – stub-based autocomplete support
- `compile_commands.json` – always non-empty
- `tools/arduino-lib.sh` – install/remove libraries safely
- `tools/arduino-doctor.sh` – health checks (read-only)

No global state. No hidden caches. No IDE dependency.

---

## Project layout

```text
.
├── Makefile
├── src/
│   └── main.cpp
├── core/
│   └── ArduinoCore-avr (vendored)
├── libs/
│   └── <Arduino libraries>
├── .ccdb/
│   └── stub.cpp
├── compile_commands.json
└── tools/
    ├── arduino-project-init.sh
    ├── arduino-lib.sh
    └── arduino-doctor.sh
```

## Required tools
- make
- avr-gcc
- avr-libc
- avrdude
- aduiono-cli
- bear
- clangd
- jq
- git

### Install on fedora
```bash
sudo dnf install -y \
  make \
  avr-gcc \
  avr-gcc-c++ \
  avr-libc \
  avrdude \
  arduino-cli \
  bear \
  clangd \
  jq \
  git

```

### Install on MacOS (Homebrew)
```bash
brew install \
  make \
  avr-gcc \
  avrdude \
  arduino-cli \
  bear \
  llvm \
  jq
```

