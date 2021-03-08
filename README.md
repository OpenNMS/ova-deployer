# OpenNMS Appliance Deployer Script

## Deploy the OpenNMS appliance to VMware (vCenter)
The shell script `ova-deployer.sh` deploys an OpenNMS virtual appliance to a VMware vCenter based deployment.

### Dependencies
- VMware's `ovftool`
- `jq`
- The appliance image: a `.ova` file, to be downloaded from the OpenNMS cloud portal.
- The appliance configuration: a `.json` file, to be downloaded from the OpenNMS cloud portal.
- The VMware configuration: a `.cfg` file, which contains details about the VMWare deployment. Refer to `ova-deployer.cfg` for an example.

### Usage
1. Create a configuration file with the following defined:
    - vCenter IP or hostname: `VCENTER_IP="..."`
    - VMware datacenter name `VMWARE_DATACENTER="..."`
    - VMware host or cluster name (`VMWARE_HOST="..."` or `VMWARE_CLUSTER="..."`)
    - VMware network name `VMWARE_NETWORK="..."`
    - VMware datastore name `VMWARE_DATASTORE="..."`
1. Either add `ovftool` to `$PATH` - or set environment variable `$OVF_TOOL_ENV`.
1. Run the script with mandatory arguments:
    - `-i` path to the appliance image
    - `-c` path to the appliance configuration file
    - `-w` path to the VMware configuration file
1. Enter vCenter username and password when prompted

### Output
```
$ export OVF_TOOL_ENV="/home/ulf/Downloads/VMware-ovftool/mac/ovftool"
$ ./ova-deployer.sh -i ~/Downloads/vm-img-dev.ova -c ~/Downloads/prod.json -w ./ova-deployer.cfg 
INFO: using 'ovftool' defined in OVF_TOOL_ENV: /home/ulf/Downloads/VMware-ovftool/mac/ovftool
INFO: using appliance image: '/home/ulf/Downloads/vm-img.ova'
INFO: using appliance config: '/home/ulf/Downloads/vm.json'
Opening OVA source: /home/ulf/Downloads/vm-img.ova
The manifest validates
Enter login information for target vi://192.168.2.120/
Username: administrator@vSphere.local
Password: ***********
Opening VI target: vi://administrator%40vSphere.local@192.168.2.120:443/Datacenter/host/192.168.2.5
Deploying to VI: vi://administrator%40vSphere.local@192.168.2.120:443/Datacenter/host/192.168.2.5
Transfer Completed                    
Powering on VM: OpenNMS Virtual Appliance
Task Completed                        
Completed successfully
```
