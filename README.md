# Neovim Config

My Neovim setup with a transparent theme, a file explorer, and debugging built in.

## Features

- File explorer and project-wide search
- Go to definitions, find references, and rename symbols
- Debugger with breakpoints, stepping, variables and watches
- Syntax highlighting and automatic bracket closing
- Terminal and Codex panels that stay running when hidden
- A built-in cheat sheet: **Space ?**

## Installation

### Prerequisites

You just need **Neovim 0.12+**, **curl**, and an internet connection.
[Get Neovim here](https://github.com/neovim/neovim/releases) if you need it.
The installer handles the other tools, language runtimes and plugins.

### Quick install — Linux / macOS

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/vinceruizz/nvim-config-v2/main/install.sh)
```

### Quick install — Windows (PowerShell)

```powershell
curl.exe -fL https://raw.githubusercontent.com/vinceruizz/nvim-config-v2/main/install.ps1 -o "$env:TEMP\nvim-install.ps1"
if ($LASTEXITCODE -eq 0) { powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\nvim-install.ps1" }
```

**Your existing config is backed up.** Setup detects your OS and may ask for
permission to install dependencies. Run it as your regular user, without `sudo`.
On a Mac, finish any Apple Command Line Tools prompt and rerun if needed.

### After installation

1. Choose **JetBrainsMono Nerd Font** in your terminal settings and restart it.
2. Open your project: `nvim .`
3. Press **Space ?** to see your shortcuts. Sign in if you want to use Codex.

## Keybindings

| Keys | Action |
| --- | --- |
| Space e | Switch between code and explorer |
| Space ff / Space fg | Find files / search project text |
| Space tt | Toggle terminal |
| Space cc | Toggle Codex |
| gd / gr | Go to definition / find references |
| Space rn | Rename a symbol |
| F9 | Toggle breakpoint |
| F5 | Start / continue debugging |
| F10 / F11 | Step over / into |
| Shift F11 / Shift F5 | Step out / stop debugging |
| Space du | Toggle debugger panels |
| Space ? | Open the full cheat sheet |

## Debugging

Supports **Python, JavaScript/TypeScript, C/C++, C# and Java**. Save your file,
set a breakpoint with **F9**, then press **F5** and choose how to run it.

Some projects need a build first. The [debugging guide](DEBUGGING.md) covers each
language and project-specific launch settings.

## Customization

- **Plugins:** add a file in `lua/plugins/`.
- **Shortcuts:** edit `lua/config/keymaps.lua`.
- **Editor settings:** edit `lua/config/options.lua`.
- **Theme:** edit `lua/config/theme.lua`.
- **Language tools:** edit `lua/config/lsp.lua`.

<details>
<summary>Setup notes and troubleshooting</summary>

- The installer uses Homebrew on macOS, Scoop on Windows, and your package manager
  on Linux. Windows doesn't need Git Bash or WSL.
- Full Windows setup needs x64 Neovim. Native Windows ARM64, Alpine and Nix have
  tool availability limits; older Linux versions may need manual dependencies.
- Config goes in `~/.config/nvim`, or `%LOCALAPPDATA%\nvim` on Windows. Custom XDG
  paths and `NVIM_APPNAME` work too. Language runtimes live in Neovim's data folder.
- Setup stopped? Fix the reported problem and rerun. In Neovim, try `:checkhealth`
  or `:MasonLog`. Your projects still need their own dependencies.
- To undo setup, close Neovim and put the reported backup back in place of the new config.

Prefer one identical command for all three operating systems?

```sh
nvim --headless -u NONE -i NONE -n -c "lua local s=vim.fn.system({'curl','-fsSL','https://raw.githubusercontent.com/vinceruizz/nvim-config-v2/main/scripts/install.lua'}); assert(vim.v.shell_error==0,s); assert(loadstring(s))().run()"
```

From a local checkout, use `sh install.sh --full` on Linux/macOS, or
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File install.ps1` on Windows.
Add `--dry-run` / `-DryRun` to preview. Local `sh install.sh` keeps its config-only
default; `--help` lists the other options.

</details>
