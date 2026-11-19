#!/bin/sh
# Install this Neovim config on macOS or Linux. Run --help for options.
set -eu
app=nvim
source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
# Also work when downloaded on its own or run via bash <(curl ...).
if [ ! -f "$source_dir/scripts/install-common.sh" ] || [ ! -f "$source_dir/init.lua" ]; then
    remote_dry_run=${NVIM_INSTALL_DRY_RUN:-0}; remote_config_only=0
    for argument do
        case "$argument" in
            --dry-run) remote_dry_run=1 ;;
            --config-only) remote_config_only=1 ;;
            --full) remote_config_only=0 ;;
            --help|-h)
                printf '%s\n' 'Neovim Config Installer' 'Usage: bash install.sh [--full | --config-only] [--dry-run]' \
                    'Default: install dependencies, back up your config, and set up plugins and language tools.'
                exit 0 ;;
            *) printf 'Unknown option: %s\n' "$argument" >&2; exit 1 ;;
        esac
    done
    command -v nvim >/dev/null 2>&1 || { printf '%s\n' 'Install Neovim 0.12+ first.' >&2; exit 1; }
    command -v curl >/dev/null 2>&1 || { printf '%s\n' 'Install curl first.' >&2; exit 1; }
    printf '\n%s\n\n' '=== Neovim Config Installer ==='
    NVIM_INSTALL_DRY_RUN="$remote_dry_run" NVIM_INSTALL_CONFIG_ONLY="$remote_config_only" \
        nvim --headless -u NONE -i NONE -n -c \
        "lua local ok,e=pcall(function() local s=vim.fn.system({'curl','-fsSL','https://raw.githubusercontent.com/vinceruizz/nvim-config-v2/main/scripts/install.lua'}); assert(vim.v.shell_error==0,s); assert(loadstring(s))().run({config_only=vim.env.NVIM_INSTALL_CONFIG_ONLY=='1'}) end); if not ok then io.stderr:write(tostring(e)); vim.cmd('cquit 1') end"
    exit $?
fi
. "$source_dir/scripts/install-common.sh"
install_deps=0; bootstrap=0; build_nvim=0; font=0; dry_run=0; full=0
target="${XDG_CONFIG_HOME:-$HOME/.config}/${NVIM_APPNAME:-nvim}"
usage() {
    cat <<'HELP'
Usage: sh install.sh [options]
  --target /absolute/path  Destination (default: $XDG_CONFIG_HOME/$NVIM_APPNAME)
  --install-deps           Install core packages with Homebrew/system package manager
  --build-neovim           Build stable Neovim locally (for old distro packages)
  --bootstrap              Install locked plugins, parsers, LSPs and debug adapters
  --font                   Install JetBrainsMono Nerd Font for this user
  --config-only            Copy/backup config only (the default)
  --full                   Detect OS, install all dependencies, deploy and bootstrap
  --dry-run                Print the plan without writing or downloading anything
  --help                   Show this help
System packages may require sudo with --install-deps or --full. Existing configs are backed up.
--full also installs the JDK, .NET SDK and tree-sitter CLI; legacy --bootstrap expects them installed.
HELP
}
while [ "$#" -gt 0 ]; do
    case "$1" in
        --target) [ "$#" -ge 2 ] || fail '--target needs a path'; target=$2; shift ;;
        --install-deps) install_deps=1 ;;
        --build-neovim) build_nvim=1 ;;
        --bootstrap) bootstrap=1 ;;
        --font) font=1 ;;
        --config-only) install_deps=0; bootstrap=0; build_nvim=0; font=0; full=0 ;;
        --full) full=1 ;;
        --dry-run) dry_run=1 ;;
        --help|-h) usage; exit 0 ;;
        *) fail "Unknown option: $1" ;;
    esac
    shift
done
case "$target" in /*) ;; *) fail '--target must be absolute.' ;; esac
if [ "$full" = 1 ]; then
    need nvim
    NVIM_INSTALL_SOURCE="$source_dir" NVIM_INSTALL_TARGET="$target" NVIM_INSTALL_DRY_RUN="$dry_run" \
        nvim --headless -u NONE -i NONE -n \
        -c 'lua dofile(vim.env.NVIM_INSTALL_SOURCE .. "/scripts/install.lua").run({target=vim.env.NVIM_INSTALL_TARGET})'
    exit $?
fi
if [ "$dry_run" = 1 ]; then
    note "Platform: $platform; source: $source_dir; destination: $target"
    note "Backup existing config; install-deps=$install_deps; build-neovim=$build_nvim; bootstrap=$bootstrap; font=$font"
    exit 0
fi
if [ "$install_deps" = 1 ]; then install_packages; fi
if [ "$build_nvim" = 1 ]; then
    for tool in git curl cc make cmake; do need "$tool"; done
    build_temp=$(mktemp -d)
    git clone --depth 1 --branch stable https://github.com/neovim/neovim.git "$build_temp/neovim"
    nvim_prefix="${XDG_DATA_HOME:-$HOME/.local/share}/neovim-local"
    (cd "$build_temp/neovim" && make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$nvim_prefix" && make CMAKE_INSTALL_PREFIX="$nvim_prefix" install)
    PATH="$nvim_prefix/bin:$PATH"; export PATH
    note "Built Neovim locally. Add $nvim_prefix/bin to PATH in your shell."
fi
if [ "$bootstrap" = 1 ]; then
    for tool in nvim git curl unzip cc make node npm python3 tree-sitter; do need "$tool"; done
    nvim --headless -u NONE -i NONE -n '+lua if vim.fn.has("nvim-0.12") ~= 1 then vim.cmd("cquit 1") end' +qa \
        || fail 'Neovim 0.12+ is required. Use --install-deps --build-neovim if your distro package is older.'
    tree_version=$(tree-sitter --version | awk '{print $2}')
    awk -v version="$tree_version" 'BEGIN { split(version,v,"."); exit !(v[1]>0 || v[2]>26 || (v[2]==26 && v[3]>=1)) }' \
        || fail 'Install tree-sitter CLI 0.26.1+ (for example: cargo install --locked tree-sitter-cli).'
    node -e 'if (Number(process.versions.node.split(".")[0]) < 22) process.exit(1)' \
        || fail 'Node.js 22+ is required for the language tools.'
fi
deploy_files "$source_dir" "$target" init.lua lazy-lock.json lua colors scripts install.sh install.ps1 README.md DEBUGGING.md
if [ "$font" = 1 ]; then install_font; fi
if [ "$bootstrap" = 1 ]; then
    # Tell Neovim which XDG application name to use, including custom targets.
    config_parent=$(CDPATH= cd -- "$(dirname "$target")" && pwd -P)
    config_name=$(basename "$target")
    XDG_CONFIG_HOME="$config_parent" NVIM_APPNAME="$config_name" \
        npm_config_cache="${XDG_CACHE_HOME:-$HOME/.cache}/nvim-installer/npm" \
        NVIM_INSTALL_BOOTSTRAP=1 NVIM_BOOTSTRAP_FILE="$target/scripts/bootstrap.lua" \
        nvim --headless -i NONE -n '+lua dofile(vim.env.NVIM_BOOTSTRAP_FILE)'
fi
note 'Done. Run nvim, then :checkhealth. See README.md for optional language runtimes and Codex.'
