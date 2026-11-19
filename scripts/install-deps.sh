#!/bin/sh
# System prerequisites only; portable language runtimes are installed by install.lua.
set -eu
have() { command -v "$1" >/dev/null 2>&1; }
root() {
    if [ "$(id -u)" = 0 ]; then "$@"
    elif have sudo; then sudo "$@"
    elif have doas; then doas "$@"
    else printf '%s\n' 'System packages require sudo or doas.' >&2; exit 1
    fi
}
case "$(uname -s)" in
    Darwin)
        if ! have brew; then
            curl -fsSL --retry 2 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$1/homebrew.sh"
            /bin/bash "$1/homebrew.sh"
        fi
        if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi
        # CLT may require Apple's GUI/license interaction on a fresh Mac.
        if ! xcrun --find clang >/dev/null 2>&1; then
            xcode-select --install || true
            printf '%s\n' 'Finish installing Apple Command Line Tools, then rerun the same command.' >&2
            exit 1
        fi
        brew install git unzip ripgrep python cmake make
        ;;
    Linux)
        if have apt-get; then
            root apt-get update
            root apt-get install -y git ca-certificates unzip ripgrep build-essential cmake python3 python3-venv python3-pip tar gzip xclip libicu-dev libssl-dev zlib1g
        elif have dnf; then
            root dnf install -y git ca-certificates unzip ripgrep gcc gcc-c++ make cmake python3 python3-pip tar gzip libicu openssl-libs zlib xclip
        elif have yum; then
            root yum install -y git ca-certificates unzip ripgrep gcc gcc-c++ make cmake python3 python3-pip tar gzip libicu openssl-libs zlib xclip
        elif have pacman; then
            root pacman -Syu --needed --noconfirm git ca-certificates unzip ripgrep base-devel cmake python python-pip tar gzip icu openssl zlib xclip
        elif have zypper; then
            root zypper --non-interactive install git ca-certificates unzip ripgrep gcc gcc-c++ make cmake python3 python3-pip tar gzip libicu openssl zlib xclip
        elif have apk; then
            root apk add git ca-certificates unzip ripgrep build-base cmake python3 py3-pip tar gzip bash nodejs npm openjdk21 dotnet10-sdk icu-libs libstdc++ zlib openssl xclip
        elif have xbps-install; then
            root xbps-install -Sy git ca-certificates unzip ripgrep base-devel cmake python3 python3-pip tar gzip icu openssl zlib xclip
        elif have emerge; then
            root emerge --noreplace dev-vcs/git app-misc/ca-certificates app-arch/unzip sys-apps/ripgrep sys-devel/gcc dev-build/make dev-build/cmake dev-lang/python dev-python/pip app-arch/tar app-arch/gzip dev-libs/icu x11-misc/xclip
        elif have eopkg; then
            root eopkg install -y git ca-certs unzip ripgrep gcc g++ make cmake python3 pip tar gzip icu openssl zlib xclip
        elif have nix; then
            nix profile install nixpkgs#git nixpkgs#cacert nixpkgs#unzip nixpkgs#ripgrep nixpkgs#gcc nixpkgs#gnumake nixpkgs#cmake nixpkgs#python3 nixpkgs#nodejs_22 nixpkgs#jdk21 nixpkgs#dotnet-sdk_10 nixpkgs#tree-sitter nixpkgs#xclip
        else
            printf '%s\n' 'No supported package manager found. Install Git, unzip, ripgrep, a C compiler, make, CMake and Python 3 with venv/pip, then use NVIM_INSTALL_SKIP_SYSTEM=1.' >&2
            exit 1
        fi
        # Wayland clipboard provider (where a Wayland session is active).
        if [ -n "${WAYLAND_DISPLAY:-}" ]; then
            if have apt-get; then root apt-get install -y wl-clipboard
            elif have dnf; then root dnf install -y wl-clipboard
            elif have pacman; then root pacman -S --needed --noconfirm wl-clipboard
            elif have apk; then root apk add wl-clipboard
            fi
        fi
        ;;
    *) printf '%s\n' 'This helper is for Linux and macOS; use install.lua on Windows.' >&2; exit 1 ;;
esac
