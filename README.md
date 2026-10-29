# Neovim config

Transparent Midnight UI, One Dark-inspired syntax, quiet LSP diagnostics, debugger,
Codex panel and a persistent shell terminal. Requires **Neovim 0.12+**.

## Install on macOS or Linux

Keep this directory intact, then run its installer from any working directory:

```sh
sh /path/to/nvim/install.sh --dry-run
sh /path/to/nvim/install.sh
```

The default installs only the config. It does not need a package manager, root,
or network access, so config deployment works across Linux distributions.
It copies to `${XDG_CONFIG_HOME:-$HOME/.config}/${NVIM_APPNAME:-nvim}`.
Existing destinations are moved to a timestamped sibling backup. Running from
an already-installed config creates a sibling `.tar.gz` backup without replacing
or deleting that directory. Repeated runs are supported. Source `.git`, old
backups and machine-local files are excluded from copies.

For system dependencies and plugin/tool setup:

```sh
sh /path/to/nvim/install.sh --install-deps --bootstrap --font
```

`--install-deps` supports Homebrew on macOS and apt, dnf, yum, pacman, zypper,
apk, xbps, emerge, eopkg and Nix profiles on Linux. It can use sudo or doas for
system packages. Repositories must offer the named packages; old/minimal distro
repositories may need extra repositories or manual dependency installation.
Nix profiles require flakes/nix-command to be enabled. On immutable systems,
install dependencies through the host's supported mechanism and omit this flag.
The script does not install Homebrew or reconfigure your system package sources.

Some distributions ship an older Neovim. Build stable locally instead:

```sh
sh /path/to/nvim/install.sh --install-deps --build-neovim --bootstrap
```

This uses Neovim's bundled source build under
`${XDG_DATA_HOME:-$HOME/.local/share}/neovim-local`; add its `bin` directory to
PATH afterwards. A working C/C++ toolchain, CMake, make, gettext and development
headers are required. Alpine/musl and unusual architectures may need additional
native build settings. Config deployment itself has no CPU or libc restriction;
upstream Neovim/Mason binaries and language runtimes have their own support limits.

## Tool prerequisites

Before `--bootstrap`, install Git, curl, unzip, a C compiler, make, Python 3
(with venv support), **Node.js 22+** (with npm), and **tree-sitter CLI 0.26.1+**.
The dependency option covers core tools; install a current tree-sitter CLI with
your package manager or `cargo install --locked tree-sitter-cli` using current
Rust. On macOS install Apple's Command Line Tools (`xcode-select --install`).

For Java, install **JDK 21+** and set JAVA_HOME if your installation requires it.
For C#, install the **.NET SDK** before bootstrapping. C# tool installation is
skipped when dotnet is absent. Rerun `--bootstrap` after installing it. Other
servers and parsers support Lua, Python, C/C++, JavaScript, TypeScript, JSX/TSX,
Java and C#. C/C++ uses an existing clangd or installs it through Mason.

`--bootstrap` downloads the locked plugins, syntax parsers and available Mason
tools. It exits with an error on download/build failures; see `:MasonLog` for
tool-specific failures. It can take several minutes and requires network access.
It does not install a JDK, .NET, Codex CLI or project dependencies automatically.
Install `codex` on PATH to use the Codex panel. See [DEBUGGING.md](DEBUGGING.md)
for project build/runtime requirements. Never run the whole installer with sudo.

Install JetBrainsMono Nerd Font with `--font` (or use the Kitty installer), then
select it in your terminal. Clipboard integration on Linux also needs `wl-clipboard`
for Wayland or `xclip`/`xsel` for X11. Install those through your package manager.

## Options and restore

`--target /absolute/path` chooses another destination. `--config-only` disables
dependency, build, font and bootstrap work; `--dry-run` writes nothing.
Use `--help` to see every option. Custom targets must not contain or be inside
the source directory. Neovim uses a custom target's basename as NVIM_APPNAME;
use matching XDG_CONFIG_HOME and NVIM_APPNAME when launching it afterwards.

To restore a moved backup, first move the new destination aside, then rename the
reported backup to its original path. For an in-place `.tar.gz`, extract into a
new directory, inspect it, then replace the config. Backups are never removed by
the installer. Back up `~/.local/share/nvim` separately if you need to roll back
installed plugin/tool data too.

Press **Space ?** for the cheat sheet. Start with `:checkhealth` after installation.

## Installer checks

```sh
python3 scripts/test-installers.py --kitty-source /path/to/kitty
```

These offline checks exercise deployment, backups, rollback, repeat runs, XDG
paths, shell quoting and package-manager dispatch. Package managers are mocked:
the suite never installs system packages and does not replace your live configs.
Real package availability and runtime compatibility still depend on the host.

## Sources

The build and runtime requirements follow the upstream
[Neovim build guide](https://neovim.io/doc/build/) and
[nvim-treesitter requirements](https://github.com/nvim-treesitter/nvim-treesitter).
