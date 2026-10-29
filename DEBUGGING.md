# Debugging

Open Neovim from your project root (`cd my-project && nvim`). Save your files,
place a breakpoint on an executable line, then start with **F5** or **Space d c**.
Choose a launch or attach configuration when prompted.

The debugger uses nvim-dap, nvim-dap-ui, and nvim-dap-virtual-text. Language tools
are managed by Mason, with Samsung's native ARM64 build used for C# on Apple Silicon.
Run `:DebugInstall` to install or retry all configured tools;
`:Mason` shows installation status and `:MasonLog` explains installation failures.
Restart Neovim after installing tools, especially for Java.

## Keys

All shortcuts below work in normal mode. On macOS you may need **fn + F-key**;
the Space shortcuts always provide an alternative.

| Action | Shortcut | Function key |
| --- | --- | --- |
| Show the action menu | `Space d ?` or `:DebugMenu` | |
| Start / continue | `Space d c` | F5 |
| Toggle breakpoint | `Space d b` | F9 |
| Step over (execute the current line) | `Space d o` | F10 |
| Step into (enter the current function) | `Space d i` | F11 |
| Step out (finish the current function) | `Space d O` | Shift F11 |
| Stop | `Space d t` | Shift F5 |
| Pause | `Space d p` | |
| Restart current session | `Space d r` | |
| Run last configuration | `Space d l` | |
| Run to cursor | `Space d C` | |
| Conditional breakpoint | `Space d B` | |
| Hit-count breakpoint | `Space d h` | |
| Log point (print without stopping) | `Space d L` | |
| Clear all breakpoints | `Space d x` | |
| List breakpoints in quickfix | `Space d q` | |
| Toggle debugger panels | `Space d u` | |
| Inspect value under cursor | `Space d k` | |
| Evaluate expression / visual selection | `Space d e` | |
| Toggle debug REPL | `Space d R` | |
| Choose exception breakpoints | `Space d E` | |

Breakpoints appear as red circles in the gutter; conditional breakpoints are
diamonds and log points are cyan diamonds. A hollow circle means the adapter
rejected a breakpoint. The yellow arrow and highlighted line show where execution
is paused. Breakpoints last for the current Neovim session.

## Panels

Panels open when a debug session initializes and stay open after it ends so you
can read the output. Close them with `Space d u`. Use your existing Ctrl h/j/k/l
keys to move between windows.

- **Scopes:** variables in the selected stack frame. Enter expands a value;
  `e` edits it when the adapter supports that.
- **Watches:** enter insert mode, type an expression, and press Enter to watch it.
  `d` removes a watch; `e` edits it.
- **Stacks:** threads and stack frames. `o` jumps to the selected frame.
- **Breakpoints:** `o` jumps to the source; `t` toggles a breakpoint.
- **REPL:** evaluate expressions while paused.
- **Console:** program input and output for integrated-terminal launches.

Variable values also appear beside source lines when a Tree-sitter parser and
locals queries are available for the language. Install parsers with `:TSInstall`
(for example `:TSInstall python c cpp javascript typescript java c_sharp`).
Scopes, watches, and evaluation work without these annotations.

## Language setup

| Language | Adapter | Before starting |
| --- | --- | --- |
| C / C++ | CodeLLDB | Compile with debug symbols: `clang++ -g -O0 main.cpp -o app` (or `clang` for C). F5 prompts for the executable. |
| Python | debugpy | Launch the current file. Uses `$VIRTUAL_ENV`, project `.venv` or `venv`, then `python3`. |
| JavaScript / TypeScript | vscode-js-debug | Launch JavaScript or native TypeScript with a compatible Node.js version, attach to a Node process, or launch Chrome against a running dev server. |
| C# | netcoredbg | Install the .NET SDK, run `dotnet build`, then select your application's DLL under `bin/Debug/<framework>/`. |
| Java | java-debug + JDT LS | Install JDK 21 or newer, set `JAVA_HOME`, then open a Java file in a Maven/Gradle project. Wait for indexing; F5 discovers main classes. |

Your installed Node 26 can debug TypeScript directly when the file uses syntax
supported by Node's built-in TypeScript handling. Choose **Node: current file**.
TSX and projects that require compilation still need their normal build or
development runner and source maps. For compiled Node projects, start the built JavaScript with `node --inspect-brk
dist/main.js` and choose **Node: attach**, or supply a project launch configuration.
For browser projects, start the dev server and choose **Chrome: web app**. Set
`sourceMap: true` in your TypeScript compiler settings for compiled projects.
The direct Node launch entry does not handle raw TSX.

Local verification passed JavaScript and native TypeScript breakpoints, evaluation,
and stepping, plus Java and ARM64 .NET 10 launches and breakpoints. Compiled
TypeScript source-map breakpoints did not bind before the short smoke-test
program exited, even with `pauseForSourceMap` enabled. That path remains unverified;
you can debug native TypeScript, or set `sourceMaps: false` in a project launch
configuration and place breakpoints in the generated JavaScript.

Python attach expects a local debugpy listener on port 5678. For example, install
debugpy in the project's environment and run `python -m debugpy --listen 5678
--wait-for-client app.py`.

On Apple Silicon, `:DebugInstall` installs Samsung's official native ARM64
netcoredbg 3.2.0-1092 build (with SHA-256 verification) under Neovim's data directory
at `debuggers/netcoredbg/`. The C# adapter uses that build with native ARM64 .NET;
Rosetta is not required. On other platforms it uses Mason's netcoredbg package.
The installer can also be run manually:

```sh
sh ~/.config/nvim/scripts/install-netcoredbg-arm64.sh ~/.local/share/nvim/debuggers
```

If you use nvm, launch Neovim from a shell where `node --version` works. After
installing or switching runtimes, restart Neovim so its environment is updated.

## Project configurations

nvim-dap automatically reads `.vscode/launch.json` from the working directory.
Use it for arguments, environment variables, module launches, build output paths,
and framework-specific settings. Use valid JSON (no comments or trailing commas).
Registered adapter types are `codelldb`, `python`, `pwa-node`, `pwa-chrome`,
`coreclr`, and `java`; `node` and `chrome` are aliases.

Example for a compiled TypeScript application:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug compiled TypeScript",
      "type": "pwa-node",
      "request": "launch",
      "program": "${workspaceFolder}/dist/main.js",
      "cwd": "${workspaceFolder}",
      "sourceMaps": true,
      "outFiles": ["${workspaceFolder}/dist/**/*.js"],
      "console": "integratedTerminal",
      "args": [],
      "env": { "NODE_ENV": "development" }
    }
  ]
}
```

Compile before launching; VS Code `preLaunchTask` build tasks are not executed by
nvim-dap. Attach, expression editing, and exception filters depend on adapter and
runtime support. If a session fails, inspect `:DapShowLog` and `:messages`.

See the upstream [Java setup requirements](https://github.com/mfussenegger/nvim-jdtls#configuration)
and [Samsung's native macOS debugger release](https://github.com/Samsung/netcoredbg/releases/tag/3.2.0-1092)
for runtime and platform details.
