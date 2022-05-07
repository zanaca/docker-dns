import platform
import os
from OpenSSL import crypto
import shutil

import config

on_macos = platform.uname().system.lower() == 'darwin'
on_windows = platform.uname().system.lower() == 'windows'
on_linux = platform.uname().system.lower() == 'linux'
on_wsl = on_linux and 'microsoft' in platform.uname().release.lower()


def is_supported():
    return not on_windows


def is_os_supported(os=None):
    if not os or os not in config.SUPPORTED_OS_VERSIONS:
        return False

    os_major, os_minor, _ = f'{config.OS_VERSION}.0.0'.split('.', 2)
    os_min_major, os_min_minor, _ = f'{config.SUPPORTED_OS_VERSIONS.get(os).get("min")}.0.0'.split('.', 2)
    os_max_major, os_max_minor, _ = f'{config.SUPPORTED_OS_VERSIONS.get(os).get("max")}.0.0'.split('.', 2)

    if int(os_major) < int(os_min_major) or \
            int(os_major) == int(os_min_major) and int(os_minor) < int(os_min_minor):
        print(f'ERROR: Your OS version is not supported.\n'
              f'Min version: {config.SUPPORTED_OS_VERSIONS.get(os).get("min")}\n'
              f'Sys version: {config.OS_VERSION}')
        return False

    if int(os_major) > int(os_max_major) or \
            int(os_major) == int(os_max_major) and int(os_minor) > int(os_max_minor):
        print(f'WARNING: Your OS is newer than the last tested version.\n'
              f'Tested version: {config.SUPPORTED_OS_VERSIONS.get(os).get("max")}\n'
              f'System version: {config.OS_VERSION}')

    return True


def is_tunnel_needed():
    return on_macos or on_wsl


def create_cache_folder():
    if not os.path.exists(f'{config.BASE_PATH}/.cache'):
        os.mkdir(f'{config.BASE_PATH}/.cache')

    if not os.path.isdir(f'{config.BASE_PATH}/.cache'):
        os.unlink(f'{config.BASE_PATH}/.cache')
        os.mkdir(f'{config.BASE_PATH}/.cache')


def read_cache(item):
    create_cache_folder()

    if not os.path.exists(f'{config.BASE_PATH}/.cache/{item}'):
        return None

    return open(f'{config.BASE_PATH}/.cache/{item}', 'r').read()


def write_cache(item, value):
    create_cache_folder()

    return open(f'{config.BASE_PATH}/.cache/{item}', 'w').write(value)


def is_super_user():
    return os.geteuid() == 0


def generate_certificate(
    tld=None,
    cert_file='/dev/null',
    key_file='/dev/null'
):
    if not tld:
        raise('No top level domain informed')

    k = crypto.PKey()
    k.generate_key(crypto.TYPE_RSA, 4096)
    cert = crypto.X509()
    # cert.get_subject().C = countryName
    # cert.get_subject().ST = stateOrProvinceName
    # cert.get_subject().L = localityName
    # cert.get_subject().O = organizationName
    # cert.get_subject().OU = organizationUnitName
    cert.get_subject().CN = f'*.{tld}'
    # cert.get_subject().emailAddress = emailAddress
    cert.set_serial_number(0)
    cert.gmtime_adj_notBefore(0)
    cert.gmtime_adj_notAfter(3600 * 24 * 365 * 10)
    cert.set_issuer(cert.get_subject())
    cert.set_pubkey(k)
    cert.sign(k, 'sha512')
    with open(cert_file, "wt") as f:
        f.write(crypto.dump_certificate(
            crypto.FILETYPE_PEM, cert).decode("utf-8"))
    with open(key_file, "wt") as f:
        f.write(crypto.dump_privatekey(crypto.FILETYPE_PEM, k).decode("utf-8"))


def check_if_installed():
    return os.path.exists(f'{config.BASE_PATH}/.cache/INSTALLED')


def remove_dir(base_path):
    for filename in os.listdir(base_path):
        if filename in ['.', '..']:
            continue
        file_path = os.path.join(base_path, filename)
        try:
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
        except Exception as e:
            print('Failed to delete %s. Reason: %s' % (file_path, e))
    os.rmdir(base_path)


def change_permissions_recursive(path, mode):
    for root, dirs, files in os.walk(path, topdown=False):
        for dir in [os.path.join(root, d) for d in dirs]:
            os.chmod(dir, mode)
    for file in [os.path.join(root, f) for f in files]:
        os.chmod(file, mode)


def change_owner_recursive(path, uid, gid=None):
    if not gid:
        gid = uid
    for root, dirs, files in os.walk(path, topdown=False):
        for dir in [os.path.join(root, d) for d in dirs]:
            os.chown(dir, uid, gid)
    for file in [os.path.join(root, f) for f in files]:
        os.chown(file, uid, gid)
