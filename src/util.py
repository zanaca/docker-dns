import platform
import os
from OpenSSL import crypto, SSL

import config

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


def write_cache(item, value):
    create_cache_folder()

    return open(f'.cache/{item}', 'w').write(value)


def check_if_root():
    if os.geteuid() != 0:
        exit("You need to have root privileges to run this script.\nPlease try again, this time using 'sudo'. Exiting.")

def generate_certificate(
    tld=config.TOP_LEVEL_DOMAIN
    cert_file=f'/tmp/{config.TOP_LEVEL_DOMAIN}.cert',
    key_file=f'/tmp/{config.TOP_LEVEL_DOMAIN}.key'
    ):
    k = crypto.PKey()
    k.generate_key(crypto.TYPE_RSA, 4096)
    cert = crypto.X509()
    # cert.get_subject().C = countryName
    # cert.get_subject().ST = stateOrProvinceName
    # cert.get_subject().L = localityName
    # cert.get_subject().O = organizationName
    # cert.get_subject().OU = organizationUnitName
    cert.get_subject().CN = f'*.{tld}''
    # cert.get_subject().emailAddress = emailAddress
    cert.set_serial_number(0)
    cert.gmtime_adj_notBefore(0)
    cert.gmtime_adj_notAfter(3600 * 24 * 365 * 10)
    cert.set_issuer(cert.get_subject())
    cert.set_pubkey(k)
    cert.sign(k, 'sha512')
    with open(cert_file, "wt") as f:
        f.write(crypto.dump_certificate(crypto.FILETYPE_PEM, cert).decode("utf-8"))
    with open(key_file, "wt") as f:
        f.write(crypto.dump_privatekey(crypto.FILETYPE_PEM, k).decode("utf-8"))