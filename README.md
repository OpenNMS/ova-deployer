# OpenNMS Appliance Deployer Script

## Deploy the OpenNMS appliance to VMware (vCenter)
The Python script `ova_deployer.py` deploys an OpenNMS virtual appliance to a VMware vCenter based deployment.

### Dependencies
- VMware's `ovftool` - https://developer.vmware.com/tool/ovf
- Python 3.6+
- The appliance image: a `.ova` file, to be downloaded from the OpenNMS cloud portal.
- The appliance configuration: a `.json` file, to be downloaded from the OpenNMS cloud portal.

### Usage
1. Either add `ovftool` to `$PATH` - or set environment variable `$OVF_TOOL_ENV`.
2. Update the application configuration `.json` with any additional configuration, such as NTP server, static IPs, proxies, etc.
   1. Any IP addresses defined in the application configuration must conform to [CIDR notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)
3. Run the script, providing the path to the OVA image, application configuration, vCenter datastore, vCenter network and VI locator.
4. Enter the vCenter username and password when prompted.

```
ova_deployer.py [-h] -c path -ds DATASTORE -nw NETWORK [-n NAME] [-v] [-t] [-i] image locator

Utility to deploy the OpenNMS appliance to a VMWare vCenter based deployment. Leverages 'ovftool'; which must be defined in environment variable OVF_TOOL_ENV or set in PATH.

positional arguments:
  image                 Path to the appliance image
  locator               Target URL locator which specifies either a location in the vCenter inventory or on an ESX Server.

optional arguments:
  -h, --help            show this help message and exit
  -c path, --config path
                        Path to the appliance configuration file
  -ds DATASTORE, --datastore DATASTORE
                        Target datastore name for the appliance
  -nw NETWORK, --network NETWORK
                        Target network for the appliance
  -n NAME, --name NAME  Name for the appliance
  -v, --verbose         Enable verbose logging
  -t, --thin            Use thin disk provisioning instead of thick
  -i, --insecure        Disable SSL verification
```

### Examples
Deploys the `vm-img-uc20.ova` appliance image to the `prod-datastore` on the `prod-network` network to the vCenter at 192.168.2.120, host 192.168.2.5
`python3 ova_deployer.py -c virtual-device-5a1d14c4-cc4c-4fbd-b635-cde736c99d49.json -ds prod-datastore -nw prod-network vm-img-uc20.ova vi://192.168.2.120/Datacenter/host/192.168.2.5`

Same as above, but using a custom appliance name, and with thin disk provisioning
`python3 ova_deployer.py -c virtual-device-5a1d14c4-cc4c-4fbd-b635-cde736c99d49.json -ds prod-datastore -nw prod-network --name 'Store #1291 Appliance' --thin vm-img-uc20.ova vi://192.168.2.120/Datacenter/host/192.168.2.5`
