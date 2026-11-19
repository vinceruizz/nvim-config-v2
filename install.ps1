# Native Windows entry point; also works when downloaded by itself.
param([switch]$DryRun, [switch]$ConfigOnly)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) { throw 'Install Neovim 0.12+ first.' }
if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) { throw 'Install curl first.' }
Write-Host "`n=== Neovim Config Installer ===`n" -ForegroundColor Cyan
$oldSource = $env:NVIM_INSTALL_SOURCE
$oldDryRun = $env:NVIM_INSTALL_DRY_RUN
$oldConfigOnly = $env:NVIM_INSTALL_CONFIG_ONLY
try {
    $env:NVIM_INSTALL_DRY_RUN = if ($DryRun) { '1' } else { '0' }
    $env:NVIM_INSTALL_CONFIG_ONLY = if ($ConfigOnly) { '1' } else { '0' }
    $source = Join-Path $PSScriptRoot 'scripts\install.lua'
    if (Test-Path $source) {
        $env:NVIM_INSTALL_SOURCE = $source
        $lua = "lua dofile(vim.env.NVIM_INSTALL_SOURCE).run({config_only=vim.env.NVIM_INSTALL_CONFIG_ONLY=='1'})"
    } else {
        $lua = "lua local s=vim.fn.system({'curl','-fsSL','https://raw.githubusercontent.com/vinceruizz/nvim-config-v2/main/scripts/install.lua'}); assert(vim.v.shell_error==0,s); assert(loadstring(s))().run({config_only=vim.env.NVIM_INSTALL_CONFIG_ONLY=='1'})"
    }
    $lua = $lua -replace '^lua ', ''
    $lua = "lua local ok,e=pcall(function() $lua end); if not ok then io.stderr:write(tostring(e)); vim.cmd('cquit 1') end"
    & nvim --headless -u NONE -i NONE -n -c $lua
    if ($LASTEXITCODE -ne 0) { throw 'Setup stopped. Check the error above, then rerun.' }
} finally {
    $env:NVIM_INSTALL_SOURCE = $oldSource
    $env:NVIM_INSTALL_DRY_RUN = $oldDryRun
    $env:NVIM_INSTALL_CONFIG_ONLY = $oldConfigOnly
}
