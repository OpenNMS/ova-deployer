import argparse
import os
import json
import subprocess

# These properties map from the format in the appliance configuration JSON to the guest
# properties the appliance is expecting.
PROPERTIES = {
    "cloudConnect": "guestinfo.onms.cloudconnect",
    "hostname": "guestinfo.onms.hostname",
    "httpProxy": "guestinfo.onms.proxy.http",
    "httpsProxy": "guestinfo.onms.proxy.https",
    "ntpServer": "guestinfo.onms.ntp.server",
    "staticIpv4Addresses": "guestinfo.onms.network.ipv4",
    "staticIpv6Addresses": "guestinfo.onms.network.ipv6",
    "gatewayIpv4Address": "guestinfo.onms.network.gateway.ipv4",
    "gatewayIpv6Address": "guestinfo.onms.network.gateway.ipv6",
    "dnsServers": "guestinfo.onms.network.dns.servers",
    "dnsSearchNames": "guestinfo.onms.network.dns.searchnames"
}

# Helper method to validate file paths when passed in as a paramter
def __file_path(path: str) -> str:
    if not os.path.exists(path):
        raise ValueError("Not a valid path")
    return path


def __get_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="""
     Utility to deploy the OpenNMS appliance to a VMWare vCenter based deployment.
     Leverages 'ovftool'; which must be defined in environment variable OVF_TOOL_ENV or set in PATH.
     """)
    parser.add_argument('image', help="Path to the appliance image", type=__file_path)
    parser.add_argument('locator', help="Target URL locator which specifies either a location in the vCenter inventory or on an ESX Server.", type=str)
    parser.add_argument('-c', '--config', metavar="path", help="Path to the appliance configuration file", type=__file_path, required=True)
    parser.add_argument('-ds', '--datastore', type=str, help="Target datastore name for the appliance", required=True)
    parser.add_argument('-nw', '--network', type=str, help="Target network for the appliance", required=True)

    # Optional arguments
    parser.add_argument('-n', '--name', help="Name for the appliance", type=str, default="OpenNMS Virtual Appliance")
    parser.add_argument('-v', '--verbose', action='store_true', help="Enable verbose logging")
    parser.add_argument('-t', '--thin', action='store_true', help="Use thin disk provisioning instead of thick")
    parser.add_argument('-i', '--insecure', action='store_true', help="Disable SSL verification")
    return parser

# Check the OVF tool is accessible, and returns the path to invoke it if it is.
def __validate_ovf_tool() -> str:
    # Check for the environment variable first, if it's not set we'll assume `ovftool` is available on the PATH.
    ovf_tool = os.getenv('OVF_TOOL_ENV', "ovftool")
    subprocess.run([ovf_tool, "--version"], check=True)

    return ovf_tool

# Validate the application configuration file, and map them into the guest properties for the VM.
def validate_appliance_config(config_path: str) -> dict:
    with open(config_path, "r") as file:
        data = json.load(file)
    if data.get('cloudConnect', "") == "":
        raise ValueError("Must include 'cloudConnect' in appliance configuration and must not be empty")

    configuration = {}
    for key, value in data.items():
        if key not in PROPERTIES:
            print(f"Ignoring unknown property '{key}'")
        elif not value:
            print(f"Ignoring empty property '{key}'")
        else:
            configuration[PROPERTIES[key]] = value if type(value) == str else ','.join(value)
    return configuration

# Builds the long string of arguments to pass to OVF tool based on what was passed in
def __generate_ovf_args(ovf_tool: str, appliance_config: dict, settings: dict):
    ovf_args = [ovf_tool]
    ovf_args.append(f"--name={settings['name']}")
    ovf_args.append("--acceptAllEulas")
    if settings['insecure']:
        ovf_args.append("--noSSLVerify")
    if settings['verbose']:
        ovf_args.append("--X:logLevel=verbose")
    ovf_args.append(f"--diskMode={'thin' if settings['thin_disk'] else 'thick'}")
    ovf_args.append(f"--datastore={settings['datastore']}")
    ovf_args.append(f"--net:Network 1={settings['network']}")
    ovf_args.append("--allowExtraConfig")
    for key, value in appliance_config.items():
        ovf_args.append(f"--extraConfig:{key}={value}")
    ovf_args.append("--powerOn")

    return ovf_args


if __name__ == '__main__':
    ARGS = __get_parser().parse_args()
    OVF_TOOL = __validate_ovf_tool()
    APPLIANCE_CONFIG = validate_appliance_config(ARGS.config)

    # Will prompt for vSphere username and password
    subprocess.run(
        __generate_ovf_args(OVF_TOOL, APPLIANCE_CONFIG, {
            'datastore': ARGS.datastore,
            'network': ARGS.network,
            'name': ARGS.name,
            'verbose': ARGS.verbose,
            'thin_disk': ARGS.thin,
            'insecure': ARGS.insecure,
        }) + [ARGS.image, ARGS.locator],
        check=True
    )
