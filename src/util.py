import platform
import os

on_macos = platform.uname().system.lower() == 'darwin'
on_windows = platform.uname().system.lower() == 'microsoft'
on_linux = platform.uname().system.lower() == 'linux'
on_wsl = "microsoft" in platform.uname().release.lower()


def is_supported():
    return not on_windows


def is_tunnel_needed():
    return on_macos or on_wsl


def create_cache_folder():
    if not os.path.exists('.cache'):
        os.mkdir('.cache')

    if not os.path.isdir('.cache'):
        os.unlink('.cache')
        os.mkdir('.cache')


def read_cache(item):
    create_cache_folder()

    if not os.path.exists(f'.cache/{item}'):
        return None

    return open(f'.cache/{item}', 'r').read()
