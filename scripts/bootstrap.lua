-- Called only by install.sh --bootstrap. Never run editor setup as root.
local function bootstrap()
    require("lazy").install({ wait = true, lockfile = true })
    require("lazy").restore({ wait = true })
    local plugins = require("lazy.core.config").plugins
    for name, plugin in pairs(plugins) do
        assert(plugin._.installed, "Plugin installation failed: " .. name)
        for _, task in ipairs(plugin._.tasks or {}) do
            assert(not task:has_errors(), "Plugin task failed: " .. name)
        end
    end
    require("lazy").load({ plugins = { "nvim-treesitter", "nvim-lspconfig", "nvim-dap" } })

    local languages = { "lua", "python", "c", "cpp", "javascript", "typescript", "tsx", "java", "c_sharp" }
    require("nvim-treesitter").install(languages):wait(300000)
    for _, language in ipairs(languages) do
        assert(vim.treesitter.language.add(language), "Parser installation failed: " .. language)
    end

    local registry = require("mason-registry")
    local refreshed, registry_ok = false, false
    registry.refresh(function(ok) registry_ok, refreshed = ok, true end)
    assert(vim.wait(120000, function() return refreshed end, 100) and registry_ok,
        "Mason registry refresh failed; see :MasonLog")

    local packages = {
        "lua-language-server", "pyright", "typescript-language-server", "jdtls",
        "codelldb", "debugpy", "js-debug-adapter", "java-debug-adapter",
    }
    if vim.fn.executable("clangd") ~= 1 then packages[#packages + 1] = "clangd" end
    local machine = vim.uv.os_uname()
    local apple_silicon = machine.sysname == "Darwin" and machine.machine == "arm64"
    if vim.fn.executable("dotnet") == 1 then
        packages[#packages + 1] = "csharp-language-server"
        if not apple_silicon then packages[#packages + 1] = "netcoredbg" end
    else
        print("Skipped C# tools: install the .NET SDK, then rerun --bootstrap.")
    end
    if vim.fn.executable("java") ~= 1 then
        print("Java tools installed; install JDK 21+ before opening Java projects.")
    end

    local failures = {}
    for _, name in ipairs(packages) do
        local package = registry.get_package(name)
        if not package:is_installed() and not package:is_installing() then
            package:once("install:failed", function() failures[name] = true end)
            package:install()
        end
    end
    assert(vim.wait(900000, function()
        if next(failures) then return true end
        for _, name in ipairs(packages) do
            if not registry.get_package(name):is_installed() then return false end
        end
        return true
    end, 250), "Tool installation timed out; see :MasonLog")
    assert(not next(failures), "Tool installation failed: " .. table.concat(vim.tbl_keys(failures), ", ")
        .. ". See :MasonLog; on unsupported architectures/libc install these tools manually.")

    if apple_silicon and vim.fn.executable("dotnet") == 1 then
        local debugger_dir = vim.fn.stdpath("data") .. "/debuggers"
        if vim.fn.executable(debugger_dir .. "/netcoredbg/netcoredbg") ~= 1 then
            local result = vim.system({ "sh", vim.fn.stdpath("config") .. "/scripts/install-netcoredbg-arm64.sh", debugger_dir },
                { text = true }):wait(180000)
            assert(result.code == 0, "Native C# debugger installation failed: " .. (result.stderr or ""))
        end
    end
    print("Plugins, syntax parsers, language servers and available debug adapters installed.")
end

local ok, err = xpcall(bootstrap, debug.traceback)
if not ok then
    vim.api.nvim_err_writeln(err)
    vim.cmd("cquit 1")
else
    vim.cmd("qa!")
end
