# Arduino Makefile Toolchain (No Arduino IDE)

An IDE-agnostic Arduino AVR workflow built around **Makefiles**, **avr-gcc**, and
**clangd**. This repo provides the `ardu` helper and a set of scripts to create
projects with vendored dependencies and a reliable `compile_commands.json`.

Goals:

- Transparent, reproducible builds (no hidden IDE state)
- Per-project vendoring (`core/`, `libs/`)
- First-class editor support via `clangd`

## 🚀 Quickstart

```bash
ardu doctor
ardu create my-project
cd my-project
make
```

`ardu create` generates `compile_commands.json` automatically, so editor support
works out of the box. You only need to run `make ccdb` manually if you changed
compiler flags / includes in the Makefile or want to force a refresh.

Why run `ardu doctor` first?

- It verifies that the required toolchain is installed (`avr-gcc`, `avrdude`, `arduino-cli`, `bear`, `clangd`, etc.).
- It fails fast with clear missing-tool errors, instead of discovering problems mid-build.
- When run inside a project, it also checks project structure and warns if `compile_commands.json` is missing.

## Contents

- [Installation](#installation)
- [Prerequisites](#prerequisites)
- [Using `ardu`](#using-ardu)
- [Project layout](#project-layout)
- [Editor integration (clangd)](#editor-integration-clangd)
- [Motivation](#motivation)
- [Troubleshooting](#troubleshooting)

## 📦 Installation

Install **arduino-build-tools** with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/kenguru33/arduino-build-tools/main/install.sh | bash
```

The installer registers a launcher at `$HOME/.local/bin/ardu`. If `ardu` is not
found, add this to your shell config:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## 🎯 Motivation

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

If something breaks, you can see _why_.

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

## 🗂️ Project layout

```text
.
├── wokwi.toml
├── diagram.json
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

## 🧰 Prerequisites

- make
- avr-gcc / avr-g++
- avr-libc
- binutils (for `avr-objcopy`, `ar`)
- avrdude
- arduino-cli
- bear
- clangd
- jq
- git

### Fedora

```bash
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | BINDIR=~/.local/bin sh
```

```bash
sudo dnf install -y \
  make \
  avr-gcc \
  avr-gcc-c++ \
  avr-libc \
  avrdude \
  bear \
  clangd \
  jq \
  git
```

### macOS (Homebrew)
Make sure you have xcode command line developer tools installed:
```bash
xcode-select --install
```

Run the following to install the latest version of avr-gcc:
```bash
brew tap osx-cross/avr
```

```bash
brew install \
  make \
  avr-gcc \
  avrdude \
  bear \
  llvm \
  jq \
  git
```

## 🧩 Using `ardu`

This repository ships a small wrapper script called `ardu` (installed to
`$HOME/.local/share/arduino-build-tools/ardu`) that invokes the per-repo
tools. It simplifies common tasks so you don't need to call the underlying
scripts directly.

Commands:

- `ardu create <project>`: create a new project skeleton in the current directory.
- `ardu install <library>`: vendor a library into the current project and update the Makefile `LIBS` list.
- `ardu remove <library>`: remove a vendored library from the current project and update the Makefile.
- `ardu doctor`: verify required tools and (when inside a project) validate project structure.

### Library install

Install a library into the current project (vendored into `libs/` and added to `LIBS = ...` in the Makefile):

```bash
cd my-project
ardu install Servo
```

Remove a library:

```bash
ardu remove Servo
```

### Common workflows

#### Create a new project

```bash
ardu create my-project
cd my-project
```

- Edit `src/main.cpp` and add sources in `src/`.
- Build the firmware with `make`.

#### Install / remove a library

```bash
ardu install Servo
ardu remove LedControl
```

This vendors libraries into `libs/` and updates the Makefile `LIBS = ...` list.

#### Health check

```bash
ardu doctor
```

Verifies availability of `avr-gcc`, `avrdude`, `arduino-cli`, and other required tools.

### Notes

- Tools live in `$HOME/.local/share/arduino-build-tools` and are invoked by the
  `ardu` wrapper. You can run the underlying scripts directly from the
  `tools/` directory inside a project when needed.
- The project Makefile provides canonical build targets and generates a
  `compile_commands.json` for editor tooling; use `make` inside a project to
  build the firmware.

`compile_commands.json` generation:

- `ardu create` generates `compile_commands.json` automatically.
- `ardu install` / `ardu remove` refresh `compile_commands.json` automatically.
- Run `make ccdb` manually only if you changed compiler flags / includes in the Makefile or you want to refresh editor state.

Makefile targets (inside a project):

- `make`: build `build/firmware.hex`
- `make ccdb`: (re)generate `compile_commands.json` for `clangd`
- `make flash`: upload firmware via `avrdude` (configure `PORT`/`BAUD` in the Makefile)
- `make clean`: remove build outputs

## 🧠 Editor integration (clangd)

All editors below rely on the compilation database `compile_commands.json` that
the project Makefile generates. Ensure the file is present at the project root
before opening the project in your editor so `clangd` can pick up the
compile flags and include paths.

### Neovim

- Install `clangd` and an LSP client (for example `neovim/nvim-lspconfig`).
- Minimal `lspconfig` snippet to add to your Neovim config:

```lua
local lspconfig = require('lspconfig')
lspconfig.clangd.setup{
  cmd = { 'clangd', '--background-index' },
  root_dir = require('lspconfig.util').root_pattern('compile_commands.json', '.git')
}
```

Open the project root in Neovim and `clangd` will use `compile_commands.json`.

### VS Code

- Install the `clangd` extension (LLVM) or the Microsoft C/C++ extension.
- Recommended workspace settings (`.vscode/settings.json`):

```json
{
  "clangd.path": "clangd",
  "clangd.arguments": ["--background-index"],
  "C_Cpp.default.compileCommands": "${workspaceFolder}/compile_commands.json"
}
```

Open the project folder in VS Code — the extension will pick up
`compile_commands.json` and enable accurate completion, diagnostics and
navigation.

### CLion

- Generate `compile_commands.json` in the project root with the Makefile.
- In CLion you can either:
  - Open the project root (CLion will detect the compilation database), or
  - Use `File → Open` and select the `compile_commands.json` to create a
    compilation-database-based project.
- (Optional) Install the `clangd` plugin from the JetBrains Marketplace to
  forward language features to the external `clangd` binary and configure the
  path in plugin settings if necessary.

### Notes

- If `clangd` doesn't pick up `compile_commands.json`, check that the file is
  at the project root and that the editor's root directory matches the project
  root. Regenerating `compile_commands.json` with the Makefile often resolves
  stale or missing flags.
- The Makefile produces a `compile_commands.json` suitable for editor tooling
  so the above setups should work out of the box once the file is present.

## 🛠️ Troubleshooting

- `ardu` not found: ensure `$HOME/.local/bin` is on your `PATH`.
- `compile_commands.json` missing or empty: it is normally generated by `ardu create` (and refreshed by `ardu install`/`ardu remove`). If needed, run `make ccdb`.
- Autocomplete is stale: rerun `make ccdb`, then restart `clangd` in your editor.
- Upload failing: check `PORT`, `BAUD`, and `MCU` in the project Makefile and verify serial device permissions.
