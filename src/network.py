import platform
import socket
import subprocess
import netifaces



LOOPBACK_NETWORK = netifaces.interfaces()[0]

def is_valid_ipv4_address(address):
    try:
        socket.inet_pton(socket.AF_INET, address)
    except AttributeError:  # no inet_pton here, sorry
        try:
            socket.inet_aton(address)
        except socket.error:
            return False
        return address.count('.') == 3
    except socket.error:  # not a valid address
        return False

    return True


def __get_unix_dns_ips():
    dns_ips = []

    with open('/etc/resolv.conf') as fp:
        for cnt, line in enumerate(fp):
            columns = line.split()
            if columns[0] == 'nameserver':
                ip = columns[1:][0]
                if is_valid_ipv4_address(ip):
                    dns_ips.append(ip)

    return dns_ips


def __get_windows_dns_ips():
    output = subprocess.check_output(["ipconfig", "-all"])
    ipconfig_all_list = output.split('\n')

    dns_ips = []
    for i in range(0, len(ipconfig_all_list)):
        if "DNS Servers" in ipconfig_all_list[i]:
            # get the first dns server ip
            first_ip = ipconfig_all_list[i].split(":")[1].strip()
            if not is_valid_ipv4_address(first_ip):
                continue
            dns_ips.append(first_ip)
            # get all other dns server ips if they exist
            k = i+1
            while k < len(ipconfig_all_list) and ":" not in ipconfig_all_list[k]:
                ip = ipconfig_all_list[k].strip()
                if is_valid_ipv4_address(ip):
                    dns_ips.append(ip)
                k += 1
            # at this point we're done
            break
    return dns_ips


def get_dns_servers():
    dns_ips = []

    if platform.system() == 'Windows':
        dns_ips = __get_windows_dns_ips()
    elif platform.system() == 'Darwin':
        dns_ips = __get_unix_dns_ips()
    elif platform.system() == 'Linux':
        dns_ips = __get_unix_dns_ips()
    else:
        dns_ips = []

    return dns_ips

