"""Check generated Kitty settings and real Zsh prompt integration in a PTY."""
import json
import os
from pathlib import Path
import pty
import select
import signal
import subprocess
import sys
import tempfile
import time

fixture = json.loads(Path(sys.argv[1]).read_text())
with tempfile.TemporaryDirectory() as temporary:
    home = Path(temporary)
    (home / '.zshenv').write_text(fixture['zshenv'])
    (home / '.zshrc').write_text(fixture['zshrc'] + '''
audit_ready() { print -r -- AUDIT_READY; }
precmd_functions+=(audit_ready)
''')
    configuration = home / 'kitty.conf'
    configuration.write_text(fixture['kittyConfig'])
    environment = {
        'HOME': str(home), 'PATH': os.environ['PATH'], 'LANG': 'C.UTF-8',
        'TERM': 'xterm-kitty', 'XDG_CONFIG_HOME': str(home / '.config'),
        'XDG_STATE_HOME': str(home / '.local/state'),
        'XDG_CACHE_HOME': str(home / '.cache'), 'STARSHIP_CONFIG': str(home / 'starship.toml'),
        'KITTY_SHELL_INTEGRATION': 'enabled', 'KITTY_WINDOW_ID': '1',
        'KITTY_INSTALLATION_DIR': str(Path(fixture['integration']).parent.parent),
        'AUDIT_KITTY_CONFIG': str(configuration),
    }
    # Parse with Kitty itself, including every generated setting and binding.
    code = '''import os
from kitty.config import load_config
options = load_config(os.environ['AUDIT_KITTY_CONFIG'])
assert options.shell_integration == frozenset({'enabled'}), options.shell_integration
assert options.confirm_os_window_close == (-1, False), options.confirm_os_window_close
'''
    subprocess.run([fixture['kitty'], '+runpy', code], env=environment, check=True)

    def exercise(automatic_integration):
        env = dict(environment)
        if automatic_integration:
            env['ZDOTDIR'] = fixture['integration']
        master, slave = pty.openpty()
        process = subprocess.Popen([fixture['zsh'], '-d', '-i'], env=env,
                                   stdin=slave, stdout=slave, stderr=slave, start_new_session=True)
        os.close(slave)
        output = bytearray()

        def wait_for(predicate):
            deadline = time.monotonic() + 15
            while not predicate(bytes(output)):
                if time.monotonic() >= deadline:
                    raise AssertionError(f'Prompt did not reach expected state: {bytes(output[-4000:])!r}')
                if select.select([master], [], [], 0.1)[0]:
                    try:
                        chunk = os.read(master, 65536)
                    except OSError:
                        chunk = b''
                    if not chunk:
                        raise AssertionError(f'Zsh exited unexpectedly: {bytes(output[-4000:])!r}')
                    output.extend(chunk)

        try:
            wait_for(lambda data: b'AUDIT_READY\r\n' in data)
            if not automatic_integration:
                # This reproduces no-rc with no Zsh module to source integration.
                assert b'\x1b]133;' not in output, repr(bytes(output))
                print('PASS: reproduces the old missing prompt-mark integration')
                return
            wait_for(lambda data: b'\x1b]133;A' in data)
            output.clear()
            os.write(master, b"(( $+functions[_zsh_highlight] && $+functions[_zsh_autosuggest_start] )) && [[ -n $LS_COLORS ]] && print AUDIT_COLORS_$((20+22))\n")
            wait_for(lambda data: b'AUDIT_COLORS_42\r\n' in data)
            print('PASS: highlighting, autosuggestions and listing colors load in Zsh')
            wait_for(lambda data: b'\x1b]133;A' in data)
            output.clear()
            os.write(master, b'not_a_valid_command_123')
            wait_for(lambda data: b'\x1b[31m' in data)
            os.write(master, b'\x15')
            print('PASS: invalid command is highlighted red by ZLE')
            output.clear()
            os.write(master, b'sleep 1\n')
            wait_for(lambda data: b'\x1b]133;C' in data)
            assert b'\x1b]133;A' not in output, repr(bytes(output))
            wait_for(lambda data: b'\x1b]133;D;0' in data and b'\x1b]133;A' in data)
            assert b'no such file or directory' not in output, repr(bytes(output))
            print('PASS: running command and idle prompt emit distinct Kitty markers')
        finally:
            if process.poll() is None:
                os.write(master, b'exit\n')
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()
            os.close(master)

    exercise(False)
    exercise(True)
