#!/bin/sh
# Samsung's official native macOS build; Mason currently supplies an Intel build.
set -eu

destination=${1:?Usage: sh install-netcoredbg-arm64.sh /path/to/nvim-data/debuggers}
archive_dir=$(mktemp -d)
trap 'rm -rf "$archive_dir"' EXIT HUP INT TERM
archive="$archive_dir/netcoredbg.zip"
curl -fsSL --retry 2 \
    https://github.com/Samsung/netcoredbg/releases/download/3.2.0-1092/netcoredbg-osx-arm64.zip \
    -o "$archive"
printf '%s  %s\n' f4fa33b3ff874910cc184b4bb3b9c56d0abdf5c6521cee0b144d7c6e4a6e59ea "$archive" | shasum -a 256 -c -
mkdir -p "$destination"
unzip -oq "$archive" 'netcoredbg/*' -d "$destination"
chmod +x "$destination/netcoredbg/netcoredbg"
