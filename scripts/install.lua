-- Cross-platform installer. Run with Neovim -u NONE; no config/plugins are loaded.
local M = {}
local uv = vim.uv or vim.loop
local script_source = debug.getinfo(1, 'S').source
local source_dir = script_source:sub(1, 1) == '@'
    and vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(script_source:sub(2)))) or nil
local raw = 'https://raw.githubusercontent.com/vinceruizz/nvim-config-v2/main/'
local archive_url = 'https://github.com/vinceruizz/nvim-config-v2/archive/refs/heads/main.zip'

function M.platform(sysname, machine)
    local os_name = ({ Darwin = 'macos', Linux = 'linux', Windows_NT = 'windows' })[sysname]
    assert(os_name, 'Unsupported operating system: ' .. tostring(sysname))
    local arch = ({ x86_64 = 'x64', amd64 = 'x64', AMD64 = 'x64', arm64 = 'arm64', aarch64 = 'arm64', ARM64 = 'arm64' })[machine]
    assert(arch, 'Unsupported CPU architecture: ' .. tostring(machine) .. ' (requires x64 or ARM64)')
    return os_name, arch
end

local function note(message) io.stdout:write('[INFO] ' .. message .. '\n'); io.stdout:flush() end
local function quote_ps(value) return "'" .. value:gsub("'", "''") .. "'" end

function M.run_command(command, windows, options)
    options = options or {}
    -- cmd/bat shims cannot be spawned directly with CreateProcess.
    if windows and (command[1]:lower():match('%.cmd$') or command[1]:lower():match('%.bat$')) then
        local escaped = {}
        for _, value in ipairs(command) do escaped[#escaped + 1] = quote_ps(value) end
        command = { 'powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command',
            "$ErrorActionPreference='Stop'; & " .. table.concat(escaped, ' ') .. '; exit $LASTEXITCODE' }
    end
    local result = vim.system(command, { cwd = options.cwd, text = true,
        stdout = options.quiet and nil or function(_, data) if data then io.stdout:write(data); io.stdout:flush() end end,
        stderr = options.quiet and nil or function(_, data) if data then io.stderr:write(data); io.stderr:flush() end end,
    }):wait(options.timeout or 1800000)
    assert(result.code == 0, 'Command failed (' .. tostring(result.code) .. '): ' .. table.concat(command, ' ')
        .. '\n' .. (result.stderr or 'See output above.'))
    return result.stdout or ''
end

local function download(url, path)
    M.run_command({ 'curl', '-fL', '--retry', '2', '--connect-timeout', '30', url, '-o', path }, false)
end
local function read_json(path)
    local content = table.concat(vim.fn.readfile(path), '\n'):gsub('^\239\187\191', '')
    return vim.json.decode(content)
end
local function write_json(path, value)
    vim.fn.mkdir(vim.fs.dirname(path), 'p')
    assert(vim.fn.writefile({ vim.json.encode(value) }, path) == 0, 'Cannot write ' .. path)
end
local function add_environment(manifest)
    for key, value in pairs(manifest.env) do vim.env[key] = value end
    local separator = vim.fn.has('win32') == 1 and ';' or ':'
    vim.env.PATH = table.concat(manifest.path, separator) .. separator .. vim.env.PATH
end
local function find_executable(names)
    for _, name in ipairs(names) do
        local path = vim.fn.exepath(name)
        if path ~= '' then return path end
    end
    error('Missing executable: ' .. table.concat(names, ' / '))
end
local function unpack_archive(path, destination, windows)
    vim.fn.mkdir(destination, 'p')
    if windows and path:match('%.zip$') then
        M.run_command({ 'powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command',
            'Expand-Archive -LiteralPath ' .. quote_ps(path) .. ' -DestinationPath ' .. quote_ps(destination) .. ' -Force' }, true)
    elseif path:match('%.zip$') then
        M.run_command({ 'unzip', '-q', '-o', path, '-d', destination }, false)
    else
        M.run_command({ 'tar', '-xzf', path, '-C', destination }, windows)
    end
end
local function only_directory(path)
    local directories = {}
    for name, kind in vim.fs.dir(path) do
        if kind == 'directory' then directories[#directories + 1] = vim.fs.joinpath(path, name) end
    end
    assert(#directories == 1, 'Unexpected archive layout: ' .. path)
    return directories[1]
end
local function copy(source, destination)
    local stat = assert(uv.fs_lstat(source), 'Missing source: ' .. source)
    if stat.type == 'directory' then
        vim.fn.mkdir(destination, 'p')
        for name in vim.fs.dir(source) do copy(vim.fs.joinpath(source, name), vim.fs.joinpath(destination, name)) end
    elseif stat.type == 'file' then
        assert(uv.fs_copyfile(source, destination), 'Cannot copy ' .. source)
    else
        error('Unexpected source entry (only ordinary files/directories are deployed): ' .. source)
    end
end

function M.deploy(source, target)
    source, target = vim.fs.normalize(vim.fs.abspath(source)), vim.fs.normalize(vim.fs.abspath(target))
    local parent = vim.fs.dirname(target)
    local function canonical(path)
        local real = uv.fs_realpath(path)
        if real then return vim.fs.normalize(real) end
        local directory = vim.fs.dirname(path)
        assert(directory ~= path, 'Cannot resolve destination: ' .. path)
        return vim.fs.joinpath(canonical(directory), vim.fs.basename(path))
    end
    local function key(path)
        path = canonical(path):gsub('\\', '/'):gsub('/$', '')
        return vim.fn.has('win32') == 1 and path:lower() or path
    end
    local src, dst = key(source), key(target)
    assert(dst ~= key(vim.fn.expand('~')) and parent ~= target, 'Refusing to replace home/root directory')
    local stage = target .. '.install-' .. uv.os_getpid()
    local backup = target .. '.backup-' .. os.date('%Y%m%d-%H%M%S') .. '-' .. uv.os_getpid()
    if src == dst then
        assert(not uv.fs_lstat(backup), 'Backup path already exists')
        copy(source, backup)
        note('Config already in place. Snapshot: ' .. backup)
        return backup
    end
    assert(dst:sub(1, #src + 1) ~= src .. '/' and src:sub(1, #dst + 1) ~= dst .. '/',
        'Source and destination must be non-nested directories')
    assert(not uv.fs_lstat(stage), 'Staging path already exists: ' .. stage)
    vim.fn.mkdir(parent, 'p')
    vim.fn.mkdir(stage, 'p')
    local ok, err = pcall(function()
        for _, name in ipairs({ 'init.lua', 'lazy-lock.json', 'lua', 'scripts', 'install.sh', 'install.ps1', 'README.md', 'DEBUGGING.md' }) do
            copy(vim.fs.joinpath(source, name), vim.fs.joinpath(stage, name))
        end
        if uv.fs_lstat(target) then
            assert(not uv.fs_lstat(backup), 'Backup path already exists')
            assert(uv.fs_rename(target, backup), 'Cannot back up config')
            note('Previous config: ' .. backup)
        end
        local moved, reason = uv.fs_rename(stage, target)
        if not moved then
            if uv.fs_lstat(backup) then assert(uv.fs_rename(backup, target), 'Cannot restore backup: ' .. backup) end
            error('Deployment failed: ' .. tostring(reason))
        end
    end)
    if uv.fs_lstat(stage) then vim.fn.delete(stage, 'rf') end
    assert(ok, err)
    return uv.fs_lstat(backup) and backup or nil
end

local function dependencies(ctx)
    local manifest = { path = {}, env = {} }
    local function path(value) table.insert(manifest.path, 1, value); add_environment({ path = { value }, env = {} }) end
    if vim.env.NVIM_INSTALL_SKIP_SYSTEM ~= '1' then
        local helper = ctx.windows and 'scripts/install-deps.ps1' or 'scripts/install-deps.sh'
        local script = vim.fs.joinpath(ctx.work, vim.fs.basename(helper))
        if ctx.source then copy(vim.fs.joinpath(ctx.source, helper), script) else download(raw .. helper, script) end
        if ctx.windows then
            M.run_command({ 'powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script,
                '-WorkDirectory', ctx.work }, true)
            local system = read_json(vim.fs.joinpath(ctx.work, 'system-environment.json'))
            for _, directory in ipairs(system.path) do path(directory) end
            for key, value in pairs(system.env) do manifest.env[key] = value; vim.env[key] = value end
        else
            M.run_command({ 'sh', script, ctx.work }, false)
        end
    end
    if ctx.os == 'macos' then
        for _, prefix in ipairs({ '/opt/homebrew', '/usr/local' }) do
            if uv.fs_stat(prefix .. '/bin/brew') then path(prefix .. '/bin'); path(prefix .. '/sbin') end
        end
    elseif ctx.os == 'linux' then
        path(vim.fn.expand('~/.nix-profile/bin'))
    end
    for _, name in ipairs({ 'git', 'rg', ctx.windows and 'gcc' or 'cc', 'make', 'cmake' }) do find_executable({ name }) end
    local python = find_executable(ctx.windows and { 'python', 'python3' } or { 'python3', 'python' })
    M.run_command({ python, '-c', 'import sys,venv; assert sys.version_info >= (3, 10), "Python 3.10+ required"' }, ctx.windows)
    manifest.env.NVIM_PYTHON = python
    vim.env.NVIM_PYTHON = python

    -- Use managed runtimes on ordinary Linux, macOS and Windows so old system
    -- Node/JDK/.NET versions do not silently produce a partial installation.
    local native_packages = ctx.os == 'linux' and (uv.fs_stat('/etc/alpine-release') or vim.fn.executable('nix') == 1)
    if native_packages then
        for _, name in ipairs({ 'node', 'npm', 'java', 'dotnet' }) do find_executable({ name }) end
    else
        local node_os = ({ macos = 'darwin', linux = 'linux', windows = 'win' })[ctx.os]
        local extension = ctx.windows and '.zip' or '.tar.gz'
        local sums = vim.fs.joinpath(ctx.work, 'node-SHASUMS256.txt')
        download('https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt', sums)
        local name, digest
        local suffix = '-' .. node_os .. '-' .. ctx.arch .. extension
        for _, line in ipairs(vim.fn.readfile(sums)) do
            local hash, file = line:match('^(%x+)%s+%*?(%S+)$')
            if file and file:sub(-#suffix) == suffix then name, digest = file, hash; break end
        end
        assert(name, 'No Node.js binary for ' .. ctx.os .. '/' .. ctx.arch)
        local archive = vim.fs.joinpath(ctx.work, name)
        download('https://nodejs.org/dist/latest-v22.x/' .. name, archive)
        -- sha256() hashes strings; use platform tools for binary files.
        if ctx.windows then
            M.run_command({ 'powershell.exe', '-NoProfile', '-Command',
                'if ((Get-FileHash -Algorithm SHA256 -LiteralPath ' .. quote_ps(archive) .. ').Hash -ne '
                    .. quote_ps(digest) .. ') { throw "Node checksum mismatch" }' }, true)
        else
            local output = M.run_command({ ctx.os == 'macos' and 'shasum' or 'sha256sum',
                unpack(ctx.os == 'macos' and { '-a', '256', archive } or { archive }) }, false, { quiet = true })
            assert(output:sub(1, 64):lower() == digest:lower(), 'Node checksum mismatch')
        end
        local node_dir = vim.fs.joinpath(ctx.tools, 'node', name:gsub('%.zip$', ''):gsub('%.tar%.gz$', ''))
        unpack_archive(archive, node_dir, ctx.windows)
        local node_root = only_directory(node_dir)
        path(ctx.windows and node_root or node_root .. '/bin')

        local java_os = ctx.os == 'macos' and 'mac' or ctx.os
        local metadata = vim.fs.joinpath(ctx.work, 'jdk.json')
        download('https://api.adoptium.net/v3/assets/latest/21/hotspot?architecture=' .. ctx.arch
            .. '&image_type=jdk&os=' .. java_os .. '&vendor=eclipse', metadata)
        local releases = read_json(metadata)
        local package = assert(releases[1], 'No JDK build for this platform').binary.package
        local jdk_archive = vim.fs.joinpath(ctx.work, package.name)
        download(package.link, jdk_archive)
        if ctx.windows then
            M.run_command({ 'powershell.exe', '-NoProfile', '-Command',
                'if ((Get-FileHash -Algorithm SHA256 -LiteralPath ' .. quote_ps(jdk_archive) .. ').Hash -ne '
                    .. quote_ps(package.checksum) .. ') { throw "JDK checksum mismatch" }' }, true)
        else
            local output = M.run_command({ ctx.os == 'macos' and 'shasum' or 'sha256sum',
                unpack(ctx.os == 'macos' and { '-a', '256', jdk_archive } or { jdk_archive }) }, false, { quiet = true })
            assert(output:sub(1, 64):lower() == package.checksum:lower(), 'JDK checksum mismatch')
        end
        local java_dir = vim.fs.joinpath(ctx.tools, 'java', package.name:gsub('%.zip$', ''):gsub('%.tar%.gz$', ''))
        unpack_archive(jdk_archive, java_dir, ctx.windows)
        local java_root = only_directory(java_dir) .. (ctx.os == 'macos' and '/Contents/Home' or '')
        manifest.env.JAVA_HOME = java_root; vim.env.JAVA_HOME = java_root; path(java_root .. '/bin')

        local dotnet = vim.fs.joinpath(ctx.tools, 'dotnet')
        local installer = vim.fs.joinpath(ctx.work, ctx.windows and 'dotnet-install.ps1' or 'dotnet-install.sh')
        download(ctx.windows and 'https://dot.net/v1/dotnet-install.ps1' or 'https://dot.net/v1/dotnet-install.sh', installer)
        local command = ctx.windows and { 'powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', installer,
            '-Channel', '10.0', '-InstallDir', dotnet, '-Architecture', ctx.arch, '-NoPath' }
            or { 'bash', installer, '--channel', '10.0', '--install-dir', dotnet, '--architecture', ctx.arch, '--no-path' }
        M.run_command(command, ctx.windows)
        manifest.env.DOTNET_ROOT = dotnet; vim.env.DOTNET_ROOT = dotnet; path(dotnet)
    end
    local node = find_executable({ 'node' })
    M.run_command({ node, '-e', 'if (+process.versions.node.split(".")[0] < 22) process.exit(1)' }, ctx.windows)
    M.run_command({ find_executable({ 'java' }), '-version' }, ctx.windows)
    M.run_command({ find_executable({ 'dotnet' }), '--list-sdks' }, ctx.windows)
    local npm = find_executable(ctx.windows and { 'npm.cmd', 'npm' } or { 'npm' })
    local prefix = vim.fs.joinpath(ctx.tools, 'npm')
    vim.env.npm_config_cache = vim.fs.joinpath(ctx.tools, 'npm-cache')
    M.run_command({ npm, 'install', '--global', '--prefix', prefix, 'tree-sitter-cli@0.26.10', '@openai/codex' }, ctx.windows)
    path(ctx.windows and prefix or prefix .. '/bin')
    if ctx.windows then
        -- Parser compilation uses vim.system(), which needs the native binary
        -- rather than npm's tree-sitter.cmd launcher.
        path(vim.fs.joinpath(prefix, 'node_modules', 'tree-sitter-cli'))
        local codex = vim.fs.find('codex.exe', {
            path = vim.fs.joinpath(prefix, 'node_modules', '@openai'), type = 'file', limit = 1,
        })[1]
        if codex then path(vim.fs.dirname(codex)) end
    end
    M.run_command({ find_executable({ 'tree-sitter' }), '--version' }, ctx.windows)
    return manifest
end

local function install_font(ctx)
    local zip = vim.fs.joinpath(ctx.work, 'font.zip')
    download('https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip', zip)
    local extracted = vim.fs.joinpath(ctx.work, 'fonts')
    unpack_archive(zip, extracted, ctx.windows)
    local destination = ctx.windows and vim.fs.joinpath(assert(vim.env.LOCALAPPDATA), 'Microsoft', 'Windows', 'Fonts')
        or ctx.os == 'macos' and vim.fn.expand('~/Library/Fonts/JetBrainsMonoNerd')
        or (vim.env.XDG_DATA_HOME or vim.fn.expand('~/.local/share')) .. '/fonts/JetBrainsMonoNerd'
    vim.fn.mkdir(destination, 'p')
    for name in vim.fs.dir(extracted) do
        if name:match('%.ttf$') or name:match('%.otf$') then
            local target = vim.fs.joinpath(destination, name)
            copy(vim.fs.joinpath(extracted, name), target)
            if ctx.windows then
                M.run_command({ 'powershell.exe', '-NoProfile', '-Command',
                    [[New-Item -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -Force | Out-Null; ]]
                    .. [[New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -Name ]]
                    .. quote_ps(name) .. ' -Value ' .. quote_ps(target) .. ' -PropertyType String -Force | Out-Null' }, true)
            end
        end
    end
    if not ctx.windows and vim.fn.executable('fc-cache') == 1 then
        M.run_command({ 'fc-cache', '-f', destination }, false)
    end
    note('Font installed. Select JetBrainsMono Nerd Font in your terminal settings.')
end

function M.install(options)
    options = options or {}
    assert(vim.fn.has('nvim-0.12') == 1, 'Neovim 0.12+ is required; update Neovim, then rerun.')
    local machine = uv.os_uname()
    local os_name, arch = M.platform(machine.sysname, machine.machine)
    local ctx = {
        os = os_name, arch = arch, windows = os_name == 'windows',
        source = options.source or source_dir, target = options.target or vim.fn.stdpath('config'),
        tools = vim.fs.joinpath(vim.fn.stdpath('data'), 'installer', 'tools'),
    }
    assert(options.config_only or vim.fs.normalize(ctx.target) == vim.fs.normalize(vim.fn.stdpath('config')),
        'For a custom full-install target, set XDG_CONFIG_HOME and NVIM_APPNAME before launching the installer.')
    note('Platform: ' .. ctx.os .. ' / ' .. ctx.arch)
    note('Config: ' .. ctx.target)
    note('Plugins/tools: ' .. vim.fn.stdpath('data'))
    if options.dry_run or vim.env.NVIM_INSTALL_DRY_RUN == '1' then
        note(options.config_only and 'Plan: back up and deploy config only.'
            or 'Plan: system prerequisites, Node 22, JDK 21, .NET 10 SDK, tree-sitter, Codex, font, config backup, plugins and language tools.')
        return
    end
    assert(options.config_only or not ctx.windows or arch == 'x64',
        'Full native Windows ARM64 setup is not supported by the compiler/debugger packages. '
            .. 'Use x64 Neovim under Windows emulation, or config_only with manually provisioned ARM64 tools.')
    assert(vim.fn.executable('curl') == 1, 'curl must be installed and available on PATH')
    ctx.work = vim.fn.tempname()
    vim.fn.mkdir(ctx.work, 'p')
    local ok, err = xpcall(function()
        local manifest
        if not options.config_only then
            vim.fn.mkdir(ctx.tools, 'p')
            note('Installing dependencies...')
            manifest = dependencies(ctx)
        end
        local source = ctx.source
        if not source then
            local zip = vim.fs.joinpath(ctx.work, 'config.zip')
            download(archive_url, zip)
            unpack_archive(zip, vim.fs.joinpath(ctx.work, 'config'), ctx.windows)
            source = only_directory(vim.fs.joinpath(ctx.work, 'config'))
        end
        note('Backing up and installing the config...')
        M.deploy(source, ctx.target)
        if manifest then
            write_json(vim.fs.joinpath(vim.fn.stdpath('data'), 'installer', 'environment.json'), manifest)
            note('Installing the font...')
            install_font(ctx)
            -- Fresh process: load the installed config, not a -u NONE session.
            local old_parent, old_name = vim.env.XDG_CONFIG_HOME, vim.env.NVIM_APPNAME
            vim.env.XDG_CONFIG_HOME, vim.env.NVIM_APPNAME = vim.fs.dirname(ctx.target), vim.fs.basename(ctx.target)
            vim.env.NVIM_INSTALL_BOOTSTRAP = '1'
            vim.env.NVIM_BOOTSTRAP_FILE = vim.fs.joinpath(ctx.target, 'scripts', 'bootstrap.lua')
            note('Setting up plugins, syntax highlighting and language tools...')
            local boot_ok, boot_err = pcall(M.run_command, { vim.v.progpath, '--headless', '-n', '-i', 'NONE',
                '-c', 'lua dofile(vim.env.NVIM_BOOTSTRAP_FILE)' }, ctx.windows)
            vim.env.XDG_CONFIG_HOME, vim.env.NVIM_APPNAME = old_parent, old_name
            assert(boot_ok, boot_err)
        end
        note('Installation complete!')
        note('Next: choose JetBrainsMono Nerd Font in your terminal, then open your project with nvim .')
        note('Space ? opens the cheat sheet. F9 sets a breakpoint; F5 starts debugging. Sign in to use Codex.')
    end, debug.traceback)
    vim.fn.delete(ctx.work, 'rf')
    assert(ok, err)
end

function M.run(options)
    local ok, err = xpcall(function() M.install(options) end, debug.traceback)
    if not ok then io.stderr:write(tostring(err) .. '\n'); vim.cmd('cquit 1') else vim.cmd('qa!') end
end

return M
