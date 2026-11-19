# My Neovim setup

A transparent theme, file explorer, debugger, and built-in terminal—with Codex
alongside your code. Supports C/C++, Python, JavaScript/TypeScript, C#, Java and Lua.

## Get it running

You'll need **Neovim 0.12+**, **curl**, and an internet connection. Paste this into
your terminal on **Linux, macOS or Windows**:

```sh
nvim --headless -u NONE -i NONE -n -c "lua local s=vim.fn.system({'curl','-fsSL','https://raw.githubusercontent.com/vinceruizz/nvim-config-v2/main/scripts/install.lua'}); assert(vim.v.shell_error==0,s); assert(loadstring(s))().run()"
```

It figures out your OS, installs the tools and plugins, and puts everything in the
right place. **Your old config gets backed up.** Give it a few minutes.

Run it as your regular user, without `sudo`. It may ask for permission to install
system packages. On a Mac, finish any Apple Command Line Tools prompt, then rerun
if needed. On Windows, use a regular PowerShell or Command Prompt window.

Once it's done:

1. Restart your terminal and choose **JetBrainsMono Nerd Font** in its settings.
2. Open your project with `nvim .`.
3. Press **Space ?** for the cheat sheet.

The installer includes the language tools, runtimes and font. Your projects still
need their own dependencies. To use Codex, you'll need to sign in.

## A few handy shortcuts

| Keys | What they do |
| --- | --- |
| Space e | Switch between your code and the explorer |
| Space ff / Space fg | Find a file / search across files |
| Space tt | Show or hide the terminal |
| Space cc | Show or hide Codex |
| gd / gr | Jump to a definition / find references |
| F9 / F5 | Set a breakpoint / start or continue debugging |
| Space ? | Open the full cheat sheet |

See the [debugging guide](DEBUGGING.md) when you're ready to debug a project.

## Something didn't work?

Check `:checkhealth` in Neovim, or `:MasonLog` if a language tool won't install.
If setup stops, fix the reported problem and run the same command again.

Want your old config back? Close Neovim and replace the new config folder with
the backup shown by the installer.

<details>
<summary>Extra setup options and platform notes</summary>

- Default config folder: `~/.config/nvim` on Linux/macOS, `%LOCALAPPDATA%\nvim` on Windows.
- Plugins and language runtimes live in Neovim's data folder. Existing global
  Node, Java and .NET installs aren't replaced. Custom XDG paths and `NVIM_APPNAME` work too.
- Setup uses Homebrew on macOS, Scoop on Windows, and your package manager on Linux.
- Full Windows setup needs x64 Neovim. Native Windows ARM64, Alpine and Nix have
  tool availability limits; older Linux versions or managed work computers may
  also need manual setup.

Already cloned the repo? Run this from its folder:

```sh
nvim --headless -u NONE -i NONE -n -c "lua dofile('scripts/install.lua').run()"
```

Replace `.run()` with `.run({dry_run=true})` to preview, or
`.run({config_only=true})` to skip dependency installation. The older
`sh install.sh --help` options still work on Linux/macOS.

Working on the installer? Run its offline checks with:

```sh
nvim --headless -u NONE -i NONE -n -c "luafile scripts/test-cross-platform.lua"
```

</details>
