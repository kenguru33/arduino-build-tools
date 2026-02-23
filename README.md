# Arduino Makefile Toolchain (No Arduino IDE)

An IDE-agnostic Arduino AVR workflow built around **Makefiles**, **avr-gcc**, and
explicitly vendored dependencies. This repo provides the `ardu` helper and a set
of scripts to create and maintain reproducible Arduino projects **without the
Arduino IDE**.

## Goals

- Transparent, reproducible builds (no hidden IDE state)
- Per-project vendoring (`core/`, `libs/`)
- Makefile-driven workflow suitable for CI and scripting
- Minimal assumptions about editor or IDE

---

## 🚀 Quickstart

```bash
ardu doctor
ardu create my-project
cd my-project
make
```

Why run `ardu doctor` first?

- Verifies that the required AVR toolchain is installed (`avr-gcc`, `avrdude`, `arduino-cli`, etc.)
- Fails fast with clear missing-tool errors
- When run inside a project, validates project structure and build artifacts

---

## 📦 Installation

```bash
curl -fsSL https://raw.githubusercontent.com/kenguru33/arduino-build-tools/main/install.sh | bash
```

Ensure `$HOME/.local/bin` is on your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## What this project gives you

- `Makefile` – firmware build, flashing, tooling
- `core/` – vendored Arduino AVR core
- `libs/` – vendored Arduino libraries
- `tools/arduino-lib.sh` – install/remove libraries safely
- `tools/arduino-doctor.sh` – health checks

No IDE dependency. No hidden caches.

---

## 🗂️ Project layout

```text
.
├── wokwi.toml
├── diagram.json
├── Makefile
├── src/
│   └── main.cpp
├── core/
│   └── ArduinoCore-avr
├── libs/
│   └── <Arduino libraries>
└── tools/
    ├── arduino-project-init.sh
    ├── arduino-lib.sh
    └── arduino-doctor.sh
```

---

## 🧰 Prerequisites

- make
- avr-gcc / avr-g++
- avr-libc
- binutils (`avr-objcopy`, `ar`)
- avrdude
- arduino-cli
- jq
- git

---

## 🧩 Using `ardu`

Commands:

- `ardu create <project>`
- `ardu install <library>`
- `ardu remove <library>`
- `ardu doctor`

---

## 🛠️ Troubleshooting

- `ardu` not found: ensure PATH is correct
- Build fails: run `ardu doctor`
- Upload failing: check `PORT`, `BAUD`, `MCU`
