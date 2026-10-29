local M = {}

function M.start()
    local mason = require("mason.settings").current.install_root_dir
    local command = mason .. "/bin/jdtls"
    local bundles = vim.fn.glob(mason .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar", true, true)
    if vim.fn.executable(command) ~= 1 then
        vim.notify("Java language server is installing; reopen this Java file when Mason finishes.", vim.log.levels.INFO)
        return
    end
    local root = vim.fs.root(0, { "mvnw", "gradlew", "pom.xml", "build.gradle", "build.gradle.kts", ".git" })
        or vim.fn.expand("%:p:h")
    local workspace = vim.fn.stdpath("cache") .. "/jdtls/" .. vim.fn.sha256(root)
    require("jdtls").start_or_attach({
        cmd = { command, "-data", workspace },
        root_dir = root,
        init_options = { bundles = bundles },
        handlers = { ["language/status"] = function() end },
    })
end

return M
