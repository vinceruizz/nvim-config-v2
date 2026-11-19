param([Parameter(Mandatory=$true)][string]$WorkDirectory)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Scoop provides per-user tools without depending on Git Bash, WSL or WinGet.
$scoopRoot = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $env:USERPROFILE 'scoop' }
$scoop = Join-Path $scoopRoot 'shims\scoop.ps1'
if (-not (Test-Path $scoop)) {
    $bootstrap = Join-Path $WorkDirectory 'scoop-install.ps1'
    & curl.exe -fsSL --retry 2 https://get.scoop.sh -o $bootstrap
    if ($LASTEXITCODE -ne 0) { throw 'Scoop download failed' }
    if ($env:GITHUB_ACTIONS -eq 'true') {
        # Hosted Windows runners are elevated; still install into the runner's user profile.
        & $bootstrap -RunAsAdmin
    } else {
        & $bootstrap
    }
    if (-not (Test-Path $scoop)) { throw 'Scoop installation failed. Run from a normal, non-administrator terminal.' }
}
& $scoop install git ripgrep python make cmake unzip gcc
if ($LASTEXITCODE -ne 0) { throw 'Scoop dependency installation failed' }
$env:Path = (Join-Path $scoopRoot 'shims') + ';' + $env:Path
# Persist the Scoop path and Python venv settings for the parent Neovim process.
$pythonRoot = Join-Path $scoopRoot 'apps\python\current'
@{
    path = @((Join-Path $scoopRoot 'shims'), $pythonRoot, (Join-Path $pythonRoot 'Scripts'), (Join-Path $scoopRoot 'apps\gcc\current\bin'))
    env = @{ PYTHONUTF8 = '1'; CC = 'gcc'; CXX = 'g++' }
} | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $WorkDirectory 'system-environment.json')
