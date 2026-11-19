#!/usr/bin/env python3
"""Offline installer checks. Package commands are mocks, never real installs."""
import argparse
import os
import re
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import sys
import unittest

parser = argparse.ArgumentParser()
parser.add_argument('--kitty-source', type=Path, default=Path.home() / '.config/kitty')
args, remaining = parser.parse_known_args()
NVIM = Path(__file__).resolve().parents[1]
KITTY = args.kitty_source.resolve()

class Installers(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='config-installer-test-')
        self.root = Path(self.temp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.log = self.root / 'commands.log'
        self.env = dict(os.environ, PATH=str(self.bin) + ':/usr/bin:/bin:/usr/sbin:/sbin',
                        XDG_CONFIG_HOME=str(self.root / 'xdg config'),
                        ZDOTDIR=str(self.root / 'zsh'), INSTALL_TEST_LOG=str(self.log))
        # Do not override HOME or touch the user's existing dotfiles.
        self.env.pop('NVIM_APPNAME', None)
        self.env.pop('NVIM_INSTALL_BOOTSTRAP', None)
        self.mock('uname', '#!/bin/sh\nprintf "%s\\n" Linux\n')
        self.mock('kitty', '#!/bin/sh\nexit 0\n')
        self.mock('id', '#!/bin/sh\nprintf "%s\\n" 1000\n')
        self.mock('sudo', '#!/bin/sh\n"$@"\n')

    def tearDown(self):
        self.temp.cleanup()

    def mock(self, name, content):
        path = self.bin / name
        path.write_text(content)
        path.chmod(0o755)
        return path

    def run_installer(self, app, *options, source=None, expect=0):
        source = source or (NVIM if app == 'nvim' else KITTY)
        result = subprocess.run(['/bin/sh', str(source / 'install.sh'), *map(str, options)],
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, expect, result.stdout + result.stderr)
        return result

    def test_fresh_copy_xdg_and_metadata_exclusion(self):
        for app, entry in [('nvim', 'init.lua'), ('kitty', 'kitty.conf')]:
            self.run_installer(app)
            target = Path(self.env['XDG_CONFIG_HOME']) / app
            self.assertTrue((target / entry).is_file())
            self.assertTrue((target / 'install.sh').is_file())
            self.assertTrue((target / 'scripts/install-common.sh').is_file())
            self.assertFalse((target / '.git').exists())
            self.assertFalse((target / 'backups').exists())
            self.assertFalse((target / '.DS_Store').exists())

    def test_backup_preserves_every_existing_file(self):
        for app in ('nvim', 'kitty'):
            target = self.root / (app + ' existing')
            (target / 'nested').mkdir(parents=True)
            (target / 'nested/keep').write_bytes(b'original\x00bytes')
            (target / '.custom').write_text('keep this')
            self.run_installer(app, '--target', target)
            backups = list(self.root.glob(target.name + '.backup-*'))
            self.assertEqual(len(backups), 1)
            self.assertEqual((backups[0] / 'nested/keep').read_bytes(), b'original\x00bytes')
            self.assertEqual((backups[0] / '.custom').read_text(), 'keep this')

    def test_repeated_in_place_install_makes_snapshot(self):
        for app in ('nvim', 'kitty'):
            target = self.root / (app + ' copied')
            self.run_installer(app, '--target', target)
            (target / 'personal-file').write_text('in-place data')
            self.run_installer(app, '--target', target, source=target)
            backups = list(self.root.glob(target.name + '.backup-*.tar.gz'))
            self.assertEqual(len(backups), 1)
            with tarfile.open(backups[0]) as archive:
                self.assertEqual(archive.extractfile('./personal-file').read(), b'in-place data')
            self.assertEqual((target / 'personal-file').read_text(), 'in-place data')

    def test_dry_run_never_creates_target_or_calls_package_manager(self):
        self.mock('apt-get', '#!/bin/sh\nprintf "called\\n" >> "$INSTALL_TEST_LOG"\n')
        for app in ('nvim', 'kitty'):
            target = self.root / (app + ' dry')
            self.run_installer(app, '--target', target, '--dry-run', '--install-deps', '--font')
            self.assertFalse(target.exists())
        self.assertFalse(self.log.exists())

    def test_shell_integration_quoting_idempotency_and_backup(self):
        target = self.root / "kitty user's config"
        zshrc = Path(self.env['ZDOTDIR']) / '.zshrc'
        zshrc.parent.mkdir()
        zshrc.write_text('# keep my settings\n')
        self.run_installer('kitty', '--target', target, '--shell-integration')
        first = zshrc.read_text()
        self.assertEqual(len(list(zshrc.parent.glob('.zshrc.backup-*'))), 1)
        self.assertEqual(first.count('midnight-glass.zsh'), 2)
        # Parse the generated source command, including embedded apostrophes.
        subprocess.run(['/bin/sh', '-n', str(zshrc)], check=True)
        self.run_installer('kitty', '--target', target, '--shell-integration')
        self.assertEqual(zshrc.read_text(), first)
        self.assertEqual(len(list(zshrc.parent.glob('.zshrc.backup-*'))), 1)

    def test_symlinked_destination_is_backed_up_without_touching_referent(self):
        for app in ('nvim', 'kitty'):
            referent = self.root / (app + '-referent')
            referent.mkdir()
            (referent / 'keep').write_text('safe')
            target = self.root / (app + '-link')
            target.symlink_to(referent, target_is_directory=True)
            self.run_installer(app, '--target', target)
            backups = list(self.root.glob(target.name + '.backup-*'))
            self.assertTrue(backups[0].is_symlink())
            self.assertEqual((referent / 'keep').read_text(), 'safe')
            self.assertFalse(target.is_symlink())

    def test_invalid_arguments_and_nested_destination(self):
        for app in ('nvim', 'kitty'):
            self.run_installer(app, '--unknown', expect=1)
            self.run_installer(app, '--target', expect=1)
            self.run_installer(app, '--target', 'relative/path', expect=1)
            source = self.root / (app + '-source')
            self.run_installer(app, '--target', source)
            self.run_installer(app, '--target', source / 'nested', source=source, expect=1)
            self.assertFalse((source / 'nested').exists())

    def test_package_manager_dispatch_without_system_changes(self):
        managers = ['apt-get', 'dnf', 'yum', 'pacman', 'zypper', 'apk',
                    'xbps-install', 'emerge', 'eopkg', 'nix']
        for manager in managers:
            mock = self.mock(manager, '#!/bin/sh\nprintf "%s\\n" "$0 $*" >> "$INSTALL_TEST_LOG"\n')
            for app in ('nvim', 'kitty'):
                self.run_installer(app, '--target', self.root / (manager + '-' + app), '--install-deps')
            self.assertIn(manager, self.log.read_text())
            mock.unlink()
        self.mock('uname', '#!/bin/sh\nprintf "%s\\n" Darwin\n')
        self.mock('brew', '#!/bin/sh\nprintf "%s\\n" "$*" >> "$INSTALL_TEST_LOG"\n')
        self.mock('xcrun', '#!/bin/sh\nexit 0\n')
        for app in ('nvim', 'kitty'):
            self.run_installer(app, '--target', self.root / ('brew-' + app), '--install-deps')
        self.assertIn('--cask kitty', self.log.read_text())

    def test_dash_compatibility(self):
        dash = shutil.which('dash')
        if not dash:
            self.skipTest('dash unavailable')
        for source in (NVIM, KITTY):
            subprocess.run([dash, '-n', str(source / 'install.sh')], check=True)
            subprocess.run([dash, '-n', str(source / 'scripts/install-common.sh')], check=True)
            result = subprocess.run([dash, str(source / 'install.sh'), '--dry-run'],
                                    env=self.env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_old_neovim_aborts_bootstrap_before_replacing_config(self):
        self.mock('nvim', '#!/bin/sh\nexit 1\n')
        self.mock('tree-sitter', '#!/bin/sh\nprintf "tree-sitter 0.26.1\\n"\n')
        self.mock('node', '#!/bin/sh\nexit 0\n')
        self.mock('npm', '#!/bin/sh\nexit 0\n')
        target = self.root / 'keep-existing-nvim'
        target.mkdir()
        (target / 'init.lua').write_text('-- original')
        result = self.run_installer('nvim', '--target', target, '--bootstrap', expect=1)
        self.assertIn('Neovim 0.12+', result.stderr)
        self.assertEqual((target / 'init.lua').read_text(), '-- original')

    def test_helpers_match(self):
        self.assertEqual((NVIM / 'scripts/install-common.sh').read_bytes(),
                         (KITTY / 'scripts/install-common.sh').read_bytes())

    def test_failed_deploy_rolls_back_previous_config(self):
        self.mock('mv', '#!/bin/sh\ncase "$1" in *-install.*) exit 1 ;; esac\n/bin/mv "$@"\n')
        for app in ('nvim', 'kitty'):
            target = self.root / (app + '-rollback')
            target.mkdir()
            (target / 'keep').write_text('original config')
            self.run_installer(app, '--target', target, expect=1)
            self.assertEqual((target / 'keep').read_text(), 'original config')
        self.assertEqual(list(self.root.glob('.*-install.*')), [])

    def test_readme_quick_start_blocks_work_without_path_edits(self):
        self.mock('git', '#!' + sys.executable + '\n'
                  'import os, shutil, sys\n'
                  'from pathlib import Path\n'
                  'assert sys.argv[1:4] == ["clone", "--depth", "1"]\n'
                  'assert sys.argv[4] == os.environ["README_TEST_URL"]\n'
                  'Path(os.environ["README_TEST_CLONE"]).write_text(sys.argv[-1])\n'
                  'shutil.copytree(os.environ["README_TEST_SOURCE"], sys.argv[-1], '
                  'ignore=shutil.ignore_patterns(".git", "backups", "__pycache__"))\n')
        self.mock('apt-get', '#!/bin/sh\nexit 0\n')
        self.mock('fc-cache', '#!/bin/sh\nexit 0\n')
        self.mock('curl', '#!' + sys.executable + '\n'
                  'import sys, zipfile\n'
                  'with zipfile.ZipFile(sys.argv[sys.argv.index("-o")+1], "w") as archive:\n'
                  '    archive.writestr("TestFont.ttf", b"test fixture")\n')
        self.env['XDG_DATA_HOME'] = str(self.root / 'data')
        self.env['README_TEST_CLONE'] = str(self.root / 'clone-path')
        for source, url, indices in [
            (KITTY, 'https://github.com/vinceruizz/kitty-config-v2.git', [0, 1]),
        ]:
            blocks = re.findall(r'```sh\n(.*?)```', (source / 'README.md').read_text(), re.S)
            for block in blocks:
                parsed = subprocess.run(['/bin/sh', '-n'], input=block, text=True, capture_output=True)
                self.assertEqual(parsed.returncode, 0, parsed.stderr)
                self.assertNotIn('/path/to/', block)
            self.env['README_TEST_SOURCE'] = str(source)
            self.env['README_TEST_URL'] = url
            for index in indices:
                result = subprocess.run(['/bin/sh', '-c', blocks[index]], env=self.env,
                                        text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                clone_path = Path(Path(self.env['README_TEST_CLONE']).read_text())
                self.assertFalse(clone_path.parent.exists(), 'Quick start must clean up its download')

    def test_neovim_universal_readme_command(self):
        nvim = shutil.which('nvim')
        if not nvim:
            self.skipTest('Neovim needed to check the universal command')
        blocks = re.findall(r'```sh\n(.*?)```', (NVIM / 'README.md').read_text(), re.S)
        for block in blocks:
            result = subprocess.run(['/bin/sh', '-n'], input=block, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
        # Serve the real installer locally instead of making a network request.
        self.mock('curl', '#!' + sys.executable + '\n'
                  'import os, sys\n'
                  'from pathlib import Path\n'
                  'assert "https://raw.githubusercontent.com/vinceruizz/nvim-config-v2/main/scripts/install.lua" in sys.argv\n'
                  'sys.stdout.write(Path(os.environ["README_INSTALLER"]).read_text())\n')
        self.mock('nvim', '#!/bin/sh\nexec ' + repr(nvim) + ' "$@"\n')
        self.env['README_INSTALLER'] = str(NVIM / 'scripts/install.lua')
        self.env['NVIM_INSTALL_DRY_RUN'] = '1'
        self.env['NVIM_LOG_FILE'] = str(self.root / 'nvim.log')
        result = subprocess.run(['/bin/sh', '-c', blocks[0]], env=self.env,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Platform:', result.stdout + result.stderr)
        self.assertFalse((Path(self.env['XDG_CONFIG_HOME']) / 'nvim').exists())

    def test_downloaded_shell_entry_and_failure_exit(self):
        nvim = shutil.which('nvim')
        bash = shutil.which('bash')
        if not nvim or not bash:
            self.skipTest('Neovim and bash required')
        self.mock('nvim', '#!/bin/sh\nexec ' + repr(nvim) + ' "$@"\n')
        self.mock('curl', '#!' + sys.executable + '\n'
                  'import os,sys\nfrom pathlib import Path\n'
                  'if os.environ.get("FAIL_CURL") == "1": sys.exit(22)\n'
                  'url = sys.argv[-1]\n'
                  'name = "install.sh" if url.endswith("/install.sh") else "scripts/install.lua"\n'
                  'sys.stdout.write((Path(os.environ["ENTRY_SOURCE"]) / name).read_text())\n')
        env = dict(self.env, ENTRY_SOURCE=str(NVIM), NVIM_INSTALL_DRY_RUN='1',
                   NVIM_LOG_FILE=str(self.root / 'nvim.log'))
        url = 'https://raw.githubusercontent.com/vinceruizz/nvim-config-v2/main/install.sh'
        command = f'bash <(curl -fsSL {url})'
        result = subprocess.run([bash, '-c', command], env=env, text=True, capture_output=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Neovim Config Installer', result.stdout)
        self.assertIn('Platform:', result.stdout)
        # Test the standalone shell wrapper's inner download failure without hanging.
        standalone = self.root / 'install.sh'
        shutil.copy(NVIM / 'install.sh', standalone)
        env['FAIL_CURL'] = '1'
        result = subprocess.run([bash, str(standalone)], env=env, text=True, capture_output=True, timeout=20)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((Path(self.env['XDG_CONFIG_HOME']) / 'nvim').exists())

    def test_pacman_respects_installed_zlib_provider(self):
        env = dict(self.env, PATH=str(self.bin), WAYLAND_DISPLAY='')
        self.mock('pacman', '#!/bin/sh\n'
                  'if [ "$1" = -T ] && [ "$2" = zlib ]; then exit "$ZLIB_MISSING"; fi\n'
                  'printf "%s\\n" "$*" > "$INSTALL_TEST_LOG"\n')
        for missing in ('0', '127'):
            with self.subTest(provider_missing=missing):
                result = subprocess.run(['/bin/sh', str(NVIM / 'scripts/install-deps.sh'), str(self.root)],
                                        env=dict(env, ZLIB_MISSING=missing), text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                targets = self.log.read_text().split()
                self.assertEqual(targets[:3], ['-Syu', '--needed', '--noconfirm'])
                self.assertEqual('zlib' in targets, missing == '127')

    def test_full_linux_prerequisite_dispatch_is_offline(self):
        # Restrict PATH to mocks: no host package manager can ever execute.
        env = dict(self.env, PATH=str(self.bin), WAYLAND_DISPLAY='')
        managers = ['apt-get', 'dnf', 'yum', 'pacman', 'zypper', 'apk',
                    'xbps-install', 'emerge', 'eopkg', 'nix']
        for manager in managers:
            executable = self.mock(manager, '#!/bin/sh\nprintf "%s\\n" "$*" >> "$INSTALL_TEST_LOG"\n')
            result = subprocess.run(['/bin/sh', str(NVIM / 'scripts/install-deps.sh'), str(self.root)],
                                    env=env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('ripgrep', self.log.read_text())
            executable.unlink()
            self.log.unlink()

if __name__ == '__main__':
    unittest.main(argv=['test-installers.py', *remaining])
