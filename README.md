# Arduino Makefile Toolchain (No Arduino IDE)

This project provides a **clean, reproducible, IDE-agnostic Arduino development setup**
based on **Makefiles**, **avr-gcc**, and **clangd** — without using the Arduino IDE.
It includes a small helper script (`ardu`) and a set of vendored tools to make
common workflows (project creation, library management, health checks) fast and
reproducible across machines and CI.

It is designed for developers who want:

- full control over the build
- reproducible projects
- proper autocomplete and navigation
- zero hidden tooling or magic

---

## Installation

Install **arduino-build-tools** with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/kenguru33/arduino-build-tools/main/install.sh | bash
```

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

If something breaks, you can see _why_.

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
- arduino-cli
- bear
- clangd
- jq
- git

### Install on fedora

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

### Install on MacOS (Homebrew)

````bash
brew install \
  make \
  avr-gcc \
  avrdude \
  arduino-cli \
  bear \
  llvm \
  jq

## Using the `ardu` helper and workflows

This repository ships a small wrapper script called `ardu` (installed to
`$HOME/.local/share/arduino-build-tools/ardu`) that invokes the per-repo
tools. It simplifies common tasks so you don't need to call the underlying
scripts directly.

Commands (run from any directory):

  - `ardu create <project>` — Create a new project skeleton in the current directory.
  - `ardu install <library>` — Install a library into the current project (uses the vendored `tools/arduino-lib.sh`).
  - `ardu remove <library>` — Remove a vendored library from the current project.
  - `ardu doctor` — Run health checks to verify required tools and environment.

Common workflows

- Create a new project and start developing:

  1. `ardu create my-project`
  2. `cd my-project`
  3. Edit `src/main.cpp` and add sources in `src/`.

- Add or remove libraries for a project:

  - `ardu install Servo` — installs the `Servo` library into the project's `libs/` folder.
  - `ardu remove LedControl` — removes `LedControl` from `libs/`.

- Check system health and toolchain:

  - `ardu doctor` — verifies availability of `avr-gcc`, `avrdude`, `arduino-cli`, and other required tools.

Notes

- Tools live in `$HOME/.local/share/arduino-build-tools` and are invoked by the
  `ardu` wrapper. You can run the underlying scripts directly from the
  `tools/` directory inside a project when needed.
- The project Makefile provides canonical build targets and generates a
  `compile_commands.json` for editor tooling; use `make` inside a project to
  build the firmware.

## Editor integration (Neovim, VS Code, CLion) — using `clangd`

All editors below rely on the compilation database `compile_commands.json` that
the project Makefile generates. Ensure the file is present at the project root
before opening the project in your editor so `clangd` can pick up the
compile flags and include paths.

Neovim (recommended setup)

- Install `clangd` and an LSP client (for example `neovim/nvim-lspconfig`).
- Minimal `lspconfig` snippet to add to your Neovim config:

```lua
local lspconfig = require('lspconfig')
lspconfig.clangd.setup{
  cmd = { 'clangd', '--background-index' },
  root_dir = require('lspconfig.util').root_pattern('compile_commands.json', '.git')
}
````

Open the project root in Neovim and `clangd` will use `compile_commands.json`.

VS Code

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

CLion (using clangd)

- Generate `compile_commands.json` in the project root with the Makefile.
- In CLion you can either:
  - Open the project root (CLion will detect the compilation database), or
  - Use `File → Open` and select the `compile_commands.json` to create a
    compilation-database-based project.
- (Optional) Install the `clangd` plugin from the JetBrains Marketplace to
  forward language features to the external `clangd` binary and configure the
  path in plugin settings if necessary.

Notes

- If `clangd` doesn't pick up `compile_commands.json`, check that the file is
  at the project root and that the editor's root directory matches the project
  root. Regenerating `compile_commands.json` with the Makefile often resolves
  stale or missing flags.
- The Makefile produces a `compile_commands.json` suitable for editor tooling
  so the above setups should work out of the box once the file is present.

```

```
