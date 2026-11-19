local M = {}

function M.start()
    local mason = require("mason.settings").current.install_root_dir
    local command = mason .. "/bin/jdtls"
    local windows = vim.fn.has("win32") == 1
    local launcher = mason .. "/packages/jdtls/bin/jdtls"
    local bundles = vim.fn.glob(mason .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar", true, true)
    if windows and vim.fn.filereadable(launcher) ~= 1 or not windows and vim.fn.executable(command) ~= 1 then
        vim.notify("Java language server is installing; reopen this Java file when Mason finishes.", vim.log.levels.INFO)
        return
    end
    local root = vim.fs.root(0, { "mvnw", "gradlew", "pom.xml", "build.gradle", "build.gradle.kts", ".git" })
        or vim.fn.expand("%:p:h")
    local workspace = vim.fn.stdpath("cache") .. "/jdtls/" .. vim.fn.sha256(root)
    local cmd = windows and { vim.env.NVIM_PYTHON or "python", launcher, "-data", workspace }
        or { command, "-data", workspace }
    require("jdtls").start_or_attach({
        cmd = cmd,
        root_dir = root,
        init_options = { bundles = bundles },
        handlers = { ["language/status"] = function() end },
    })
end

return M
