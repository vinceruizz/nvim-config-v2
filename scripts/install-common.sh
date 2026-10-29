#!/bin/sh
# Shared POSIX helpers. Each config ships its own copy for standalone use.
stage=; font_temp=; build_temp=
fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }
note() { printf '%s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
need() { have "$1" || fail "Missing $1. Install it with your package manager, then rerun."; }

platform=$(uname -s)
case "$platform" in Darwin|Linux) ;; *) fail "Supported systems: macOS and Linux (found $platform)." ;; esac

as_root() {
    if [ "$(id -u)" = 0 ]; then "$@"
    elif have sudo; then sudo "$@"
    elif have doas; then doas "$@"
    else fail "Installing system packages requires sudo/doas. Install dependencies manually, then rerun without --install-deps."
    fi
}

install_packages() {
    # Core dependencies only. Language runtimes are documented separately.
    if [ "$platform" = Darwin ]; then
        need brew
        if [ "$app" = nvim ]; then
            brew install neovim git curl unzip ripgrep cmake gettext pkg-config node python ninja tree-sitter-cli
            xcrun --find clang >/dev/null 2>&1 || fail 'Install Apple Command Line Tools with xcode-select --install.'
        else
            brew install --cask kitty
            brew install curl unzip
        fi
        return
    fi
    if [ "$app" = nvim ]; then
        if have apt-get; then
            as_root apt-get update
            as_root apt-get install -y neovim git curl ca-certificates unzip ripgrep build-essential cmake ninja-build gettext pkg-config nodejs npm python3 python3-venv
        elif have dnf; then
            as_root dnf install -y neovim git curl ca-certificates unzip ripgrep gcc gcc-c++ make cmake ninja-build gettext pkgconf-pkg-config nodejs npm python3
        elif have yum; then
            as_root yum install -y neovim git curl ca-certificates unzip ripgrep gcc gcc-c++ make cmake ninja-build gettext pkgconfig nodejs npm python3
        elif have pacman; then
            as_root pacman -Syu --needed --noconfirm neovim git curl ca-certificates unzip ripgrep base-devel cmake ninja gettext pkgconf nodejs npm python
        elif have zypper; then
            as_root zypper --non-interactive install neovim git curl ca-certificates unzip ripgrep gcc gcc-c++ make cmake ninja gettext-tools pkgconf-pkg-config nodejs npm python3
        elif have apk; then
            as_root apk add neovim git curl ca-certificates unzip ripgrep build-base cmake ninja gettext-dev pkgconf linux-headers nodejs npm python3 py3-pip
        elif have xbps-install; then
            as_root xbps-install -Sy neovim git curl ca-certificates unzip ripgrep base-devel cmake ninja gettext pkg-config nodejs python3
        elif have emerge; then
            as_root emerge --noreplace app-editors/neovim dev-vcs/git net-misc/curl app-arch/unzip sys-apps/ripgrep sys-devel/gcc dev-build/make dev-build/cmake dev-build/ninja sys-devel/gettext dev-util/pkgconf net-libs/nodejs dev-lang/python
        elif have eopkg; then
            as_root eopkg install -y neovim git curl ca-certs unzip ripgrep gcc g++ make cmake ninja gettext pkg-config nodejs python3
        elif have nix; then
            nix profile install nixpkgs#neovim nixpkgs#git nixpkgs#curl nixpkgs#unzip nixpkgs#ripgrep nixpkgs#gcc nixpkgs#cmake nixpkgs#ninja nixpkgs#gettext nixpkgs#pkg-config nixpkgs#nodejs nixpkgs#python3 nixpkgs#tree-sitter
        else
            fail 'No supported package manager found. Install dependencies manually and run without --install-deps; config deployment works on any Linux distro.'
        fi
    else
        if have apt-get; then as_root apt-get update; as_root apt-get install -y kitty curl ca-certificates unzip fontconfig
        elif have dnf; then as_root dnf install -y kitty curl ca-certificates unzip fontconfig
        elif have yum; then as_root yum install -y kitty curl ca-certificates unzip fontconfig
        elif have pacman; then as_root pacman -Syu --needed --noconfirm kitty curl ca-certificates unzip fontconfig
        elif have zypper; then as_root zypper --non-interactive install kitty curl ca-certificates unzip fontconfig
        elif have apk; then as_root apk add kitty curl ca-certificates unzip fontconfig
        elif have xbps-install; then as_root xbps-install -Sy kitty curl ca-certificates unzip fontconfig
        elif have emerge; then as_root emerge --noreplace x11-terms/kitty net-misc/curl app-arch/unzip media-libs/fontconfig
        elif have eopkg; then as_root eopkg install -y kitty curl ca-certs unzip fontconfig
        elif have nix; then nix profile install nixpkgs#kitty nixpkgs#curl nixpkgs#unzip nixpkgs#fontconfig
        else fail 'Install Kitty manually, then rerun without --install-deps. Config deployment works on any Linux distro.'
        fi
    fi
}

# deploy_files takes a source, a destination, then an explicit file allowlist.
# Config source repositories, old backups and machine-local caches are not copied.
deploy_files() {
    deploy_source=$1; deploy_target=$2; shift 2
    case "$deploy_target" in /*) ;; *) fail '--target must be an absolute path.' ;; esac
    deploy_target=${deploy_target%/}
    [ -n "$deploy_target" ] && [ "$deploy_target" != "$HOME" ] || fail 'Refusing to replace / or your home directory.'
    case "$(basename "$deploy_target")" in .|..) fail 'Destination must name a config directory, not . or ..' ;; esac
    deploy_parent=$(dirname "$deploy_target")
    mkdir -p "$deploy_parent"
    deploy_parent=$(CDPATH= cd -- "$deploy_parent" && pwd -P)
    deploy_target="$deploy_parent/$(basename "$deploy_target")"
    deploy_real=$deploy_target
    if [ -d "$deploy_target" ]; then deploy_real=$(CDPATH= cd -- "$deploy_target" && pwd -P); fi
    case "$deploy_real/" in "$deploy_source/"*)
        [ "$deploy_real" = "$deploy_source" ] || fail 'Destination cannot be inside the source config.' ;;
    esac
    case "$deploy_source/" in "$deploy_real/"*)
        [ "$deploy_real" = "$deploy_source" ] || fail 'Destination cannot contain the source config.' ;;
    esac
    backup="$deploy_target.backup-$(date +%Y%m%d-%H%M%S)-$$"
    if [ "$deploy_real" = "$deploy_source" ]; then
        tar -czf "$backup.tar.gz" -C "$deploy_source" .
        note "Config already in place. Backup: $backup.tar.gz"
        return
    fi
    stage=$(mktemp -d "$deploy_parent/.${app}-install.XXXXXX")
    for deploy_entry do
        [ -e "$deploy_source/$deploy_entry" ] || fail "Missing source file: $deploy_entry"
        cp -R "$deploy_source/$deploy_entry" "$stage/"
    done
    if [ -e "$deploy_target" ] || [ -L "$deploy_target" ]; then
        mv "$deploy_target" "$backup"
        note "Previous config: $backup"
    fi
    if ! mv "$stage" "$deploy_target"; then
        if [ -e "$backup" ] || [ -L "$backup" ]; then mv "$backup" "$deploy_target"; fi
        fail 'Deployment failed; the previous config was restored.'
    fi
    stage=
    note "Installed config: $deploy_target"
}

install_font() {
    need curl; need unzip
    font_temp=$(mktemp -d)
    curl -fL --retry 2 https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -o "$font_temp/font.zip"
    unzip -q "$font_temp/font.zip" -d "$font_temp/fonts"
    if [ "$platform" = Darwin ]; then font_dir="$HOME/Library/Fonts/JetBrainsMonoNerd"
    else font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/JetBrainsMonoNerd"; fi
    mkdir -p "$font_dir"
    find "$font_temp/fonts" -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} "$font_dir/" \;
    if have fc-cache; then fc-cache -f "$font_dir"; fi
    rm -rf "$font_temp"
    font_temp=
    note "Installed JetBrainsMono Nerd Font: $font_dir"
}

cleanup_install() {
    if [ -n "${stage:-}" ]; then rm -rf "$stage"; fi
    if [ -n "${font_temp:-}" ]; then rm -rf "$font_temp"; fi
    if [ -n "${build_temp:-}" ]; then rm -rf "$build_temp"; fi
}
trap cleanup_install EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
