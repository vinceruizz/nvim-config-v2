# Neovim Config

My Neovim setup with switchable themes, a file explorer, and debugging built in.

## Features

- File explorer and project-wide search
- Go to definitions, find references, and rename symbols
- Automatic cursor-side suggestions with a scrollable menu and documentation
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
| Space fd / :Project | Change project folder by path |
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
| Space ut / Space ub | Choose theme / toggle transparency |

## Changing project folders

Press **Space fd** (or run **:Project**) to enter a folder path, with directory
completion. Relative paths start at Neovim's current working directory (`:pwd`);
absolute paths and `~` are supported. You can also enter the path directly:

```vim
:Project ../another-project
:Project ~/projects/my-app
:Project /absolute/path/to/project
```

This updates the explorer, Neovim's working directory, and project searches.
Open files remain open, and reopening the explorer keeps the selected project.
Existing terminal processes keep their own working directories.

## Suggestions

Suggestions appear beside the cursor as you type in **Python, JavaScript/TypeScript,
C/C++, C#, Java, and Lua**, once the file's language server is ready. The menu shows
up to ten rows and scrolls through longer lists; selecting an item shows available
documentation.

Matches re-rank as you type, using fuzzy matching with language-server ranking
to break ties. C/C++ suggestions focus on visible scopes; type `std::` to browse
standard-library names instead of seeing unrelated namespaces mixed in.

The menu stays hidden while naming declarations, such as `int newName`,
`const newName`, `def newName`, class names, and parameters. Types, initializer
expressions, and member references still get suggestions; the explicit `snip`
prefix also remains available. This uses syntax context, so an ambiguous bare
name (such as Python's `newName` before typing `=`) still gets completion.

- **Tab / Shift Tab**, **Down / Up**, or **Ctrl n / p**: navigate suggestions.
- **Enter** or **Ctrl y**: accept the selected suggestion. Enter inserts a normal
  newline if nothing is selected.
- **Ctrl Space**: request suggestions manually (**Ctrl x, Ctrl o** also works).
- **Ctrl e**: dismiss the menu and keep typing.

Tab still indents when the menu is closed. Normal suggestions include keywords,
variables, functions, methods, types, fields, and imports. Function-call argument
placeholders remain available, but code templates are hidden.

Type **snip** to browse explicit templates, then narrow the name (for example,
**snipmain**, **snipif**, **snipfor**, or **snipfn**, depending on the language).
Accept with Enter; **Ctrl j / Ctrl k** move between template fields. These starter
templates live in `lua/config/snippets.lua`; server-provided code templates are
filtered out of the normal menu.

## Debugging

Supports **Python, JavaScript/TypeScript, C/C++, C# and Java**. Save your file,
set a breakpoint with **F9**, then press **F5** and choose how to run it.

Some projects need a build first. The [debugging guide](DEBUGGING.md) covers each
language and project-specific launch settings.

## Customization

- **Plugins:** add a file in `lua/plugins/`.
- **Shortcuts:** edit `lua/config/keymaps.lua`.
- **Editor settings:** edit `lua/config/options.lua`.
- **Themes:** edit `lua/themes/forest-cartridge.lua` or `lua/themes/midnight.lua`.
- **Language tools:** edit `lua/config/lsp.lua`.

**Forest Cartridge** is the default: moss green, amber and soft blue on near-black,
with square borders and a retro status bar. **Midnight** keeps the original look.
Save the active palette file to see changes instantly, or run `:ThemeReload`.
Your theme and transparency choices are remembered between sessions.

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
