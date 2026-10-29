local M = {}

function M.setup()
    local dap, ui = require("dap"), require("dapui")
    local mason = require("mason.settings").current.install_root_dir
    local function bin(name) return mason .. "/bin/" .. name end

    ui.setup({
        layouts = {
            {
                position = "left", size = 42,
                elements = {
                    { id = "scopes", size = 0.35 },
                    { id = "watches", size = 0.20 },
                    { id = "stacks", size = 0.25 },
                    { id = "breakpoints", size = 0.20 },
                },
            },
            {
                position = "bottom", size = 12,
                elements = {
                    { id = "repl", size = 0.5 },
                    { id = "console", size = 0.5 },
                },
            },
        },
    })
    require("nvim-dap-virtual-text").setup({ virt_text_pos = "eol" })
    dap.listeners.after.event_initialized["debug_ui"] = function() ui.open() end
    -- Keep output and variables visible after exit; close with Space d u.

    local function highlights()
        vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#f07886" })
        vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#86dbf5" })
        vim.api.nvim_set_hl(0, "DapStopped", { fg = "#f5b66c", bold = true })
        vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#344235" })
    end
    highlights()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = highlights })
    for name, sign in pairs({
        DapBreakpoint = { "●", "DapBreakpoint" },
        DapBreakpointCondition = { "◆", "DapBreakpoint" },
        DapBreakpointRejected = { "○", "DapBreakpoint" },
        DapLogPoint = { "◆", "DapLogPoint" },
        DapStopped = { "▶", "DapStopped", "DapStoppedLine" },
    }) do
        vim.fn.sign_define(name, { text = sign[1], texthl = sign[2], linehl = sign[3] })
    end

    dap.adapters.codelldb = {
        type = "server", port = "${port}",
        executable = { command = bin("codelldb"), args = { "--port", "${port}" } },
    }
    for _, ft in ipairs({ "c", "cpp" }) do
        dap.configurations[ft] = {
            {
                name = "Launch executable (build with -g -O0)",
                type = "codelldb", request = "launch",
                program = function()
                    local path = vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
                    return path ~= "" and path or dap.ABORT
                end,
                cwd = "${workspaceFolder}", stopOnEntry = false,
            },
            {
                name = "Attach to process", type = "codelldb", request = "attach",
                pid = require("dap.utils").pick_process,
                cwd = "${workspaceFolder}",
            },
        }
    end

    dap.adapters.python = {
        type = "executable",
        command = mason .. "/packages/debugpy/venv/bin/python",
        args = { "-m", "debugpy.adapter" },
    }
    dap.configurations.python = {
        {
            name = "Python: current file", type = "python", request = "launch",
            program = "${file}", cwd = "${workspaceFolder}",
            console = "integratedTerminal", justMyCode = false,
            pythonPath = function()
                for _, env in ipairs({ vim.env.VIRTUAL_ENV or "", vim.fn.getcwd() .. "/.venv", vim.fn.getcwd() .. "/venv" }) do
                    if env ~= "" and vim.fn.executable(env .. "/bin/python") == 1 then
                        return env .. "/bin/python"
                    end
                end
                return vim.fn.exepath("python3")
            end,
        },
        {
            name = "Python: attach (debugpy --listen 5678)",
            type = "python", request = "attach",
            connect = { host = "127.0.0.1", port = 5678 }, justMyCode = false,
        },
    }

    for _, adapter in ipairs({ "pwa-node", "pwa-chrome" }) do
        dap.adapters[adapter] = {
            type = "server", host = "127.0.0.1", port = "${port}",
            executable = { command = bin("js-debug-adapter"), args = { "${port}", "127.0.0.1" } },
        }
    end
    -- Accept the common VS Code launch.json adapter names too.
    dap.adapters.node = dap.adapters["pwa-node"]
    dap.adapters.chrome = dap.adapters["pwa-chrome"]
    for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
        dap.configurations[ft] = {
            {
                name = "Node: current file (JavaScript / native TypeScript)", type = "pwa-node", request = "launch",
                program = "${file}", cwd = "${workspaceFolder}",
                sourceMaps = true, pauseForSourceMap = true, console = "integratedTerminal",
                skipFiles = { "<node_internals>/**", "**/node_modules/**" },
            },
            {
                name = "Node: attach (node --inspect)", type = "pwa-node", request = "attach",
                processId = require("dap.utils").pick_process,
                cwd = "${workspaceFolder}", sourceMaps = true, pauseForSourceMap = true,
                skipFiles = { "<node_internals>/**", "**/node_modules/**" },
            },
            {
                name = "Chrome: web app", type = "pwa-chrome", request = "launch",
                url = function()
                    local url = vim.fn.input("Dev server URL: ", "http://localhost:3000")
                    return url ~= "" and url or dap.ABORT
                end,
                webRoot = "${workspaceFolder}", sourceMaps = true,
            },
        }
    end

    local native_dotnet = vim.fn.stdpath("data") .. "/debuggers/netcoredbg/netcoredbg"
    local apple_silicon = vim.fn.has("mac") == 1 and vim.uv.os_uname().machine == "arm64"
    dap.adapters.coreclr = {
        type = "executable",
        command = apple_silicon and native_dotnet or bin("netcoredbg"),
        args = { "--interpreter=vscode" },
    }
    dap.configurations.cs = {
        {
            name = ".NET: launch DLL (dotnet build first)", type = "coreclr", request = "launch",
            program = function()
                local path = vim.fn.input("Application DLL: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
                return path ~= "" and path or dap.ABORT
            end,
            cwd = "${workspaceFolder}", console = "integratedTerminal",
        },
        {
            name = ".NET: attach", type = "coreclr", request = "attach",
            processId = require("dap.utils").pick_process,
        },
    }

    local function prompt(label, callback)
        vim.ui.input({ prompt = label }, function(value)
            if value and value ~= "" then callback(value) end
        end)
    end
    local actions = {
        { "c", "Start / continue", dap.continue, "<F5>" },
        { "b", "Toggle breakpoint", dap.toggle_breakpoint, "<F9>" },
        { "o", "Step over", dap.step_over, "<F10>" },
        { "i", "Step into", dap.step_into, "<F11>" },
        { "O", "Step out", dap.step_out, "<S-F11>" },
        { "t", "Stop debugging", dap.terminate, "<S-F5>" },
        { "p", "Pause", dap.pause },
        { "r", "Restart session", dap.restart },
        { "l", "Run last configuration", dap.run_last },
        { "C", "Run to cursor", dap.run_to_cursor },
        { "B", "Conditional breakpoint", function() prompt("Break when: ", dap.set_breakpoint) end },
        { "h", "Hit-count breakpoint", function()
            prompt("Break on hit count: ", function(value) dap.set_breakpoint(nil, value) end)
        end },
        { "L", "Log point", function()
            prompt("Log message ({expression} interpolates): ", function(value) dap.set_breakpoint(nil, nil, value) end)
        end },
        { "x", "Clear all breakpoints", dap.clear_breakpoints },
        { "q", "List breakpoints", dap.list_breakpoints },
        { "u", "Toggle debug panels", ui.toggle },
        { "e", "Evaluate expression / selection", ui.eval },
        { "R", "Toggle debug REPL", dap.repl.toggle },
        { "E", "Choose exception breakpoints", dap.set_exception_breakpoints },
        { "k", "Inspect value under cursor", require("dap.ui.widgets").hover },
    }
    M.actions = actions
    for _, action in ipairs(actions) do
        vim.keymap.set("n", "<leader>d" .. action[1], action[3], { desc = "Debug: " .. action[2] })
        if action[4] then vim.keymap.set("n", action[4], action[3], { desc = "Debug: " .. action[2] }) end
    end
    vim.keymap.set("v", "<leader>de", ui.eval, { desc = "Debug: evaluate selection" })
    local function menu()
        vim.ui.select(actions, {
            prompt = "Debugger actions",
            format_item = function(a)
                return ("Space d %s  %s%s"):format(a[1], a[2], a[4] and ("  (" .. a[4] .. ")") or "")
            end,
        }, function(action) if action then action[3]() end end)
    end
    vim.keymap.set("n", "<leader>d?", menu, { desc = "Debug: action menu" })
    vim.api.nvim_create_user_command("DebugMenu", menu, {})
    vim.api.nvim_create_user_command("DebugGuide", function()
        vim.cmd("edit " .. vim.fn.fnameescape(vim.fn.stdpath("config") .. "/DEBUGGING.md"))
    end, { desc = "Open the full debugging guide" })

    vim.api.nvim_create_user_command("DebugInstall", function()
        local registry = require("mason-registry")
        registry.refresh(function(ok)
            if not ok then
                vim.notify("Could not refresh Mason registry; see :MasonLog", vim.log.levels.ERROR)
                return
            end
            for _, name in ipairs({ "codelldb", "debugpy", "js-debug-adapter", "netcoredbg", "jdtls", "java-debug-adapter" }) do
                local package = registry.get_package(name)
                if not (apple_silicon and name == "netcoredbg") and not package:is_installed() and not package:is_installing() then
                    package:install()
                end
            end
            vim.schedule(function() vim.cmd("Mason") end)
        end)
        if apple_silicon and vim.fn.executable(native_dotnet) ~= 1 then
            vim.system({
                "sh", vim.fn.stdpath("config") .. "/scripts/install-netcoredbg-arm64.sh",
                vim.fn.stdpath("data") .. "/debuggers",
            }, { text = true }, function(result)
                vim.schedule(function()
                    vim.notify(result.code == 0 and "Native ARM64 C# debugger installed" or
                        ("C# debugger installation failed: " .. result.stderr),
                        result.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
                end)
            end)
        end
    end, { desc = "Install all configured language debuggers and Java language server" })
end

return M
