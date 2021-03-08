#!/usr/bin/env bash

# GLOBALS
OVF_TOOL=""
ONMS_APPLIANCE_CONFIG_FILE=""
ONMS_APPLIANCE_IMAGE_FILE=""
ONMS_OPT_CLOUD_CONNECT=""
ONMS_OPT_NETWORK=""
ONMS_OPT_HOSTNAME=""
ONMS_OPT_HTTP_PROXY=""
ONMS_OPT_HTTPS_PROXY=""
ONMS_OPT_VMWARE=""

requireJq() {
  if ! command -v jq > /dev/null; then
    echo "ERROR: unable to locate 'jq'. Please install it."
    exit 1
  fi
}

requireOvfTool() {
  if [ -n "$OVF_TOOL_ENV" ] && [ -x "$OVF_TOOL_ENV" ]; then
    echo "INFO: using 'ovftool' defined in OVF_TOOL_ENV: $OVF_TOOL_ENV"
    OVF_TOOL="$OVF_TOOL_ENV"
    return
  fi

  if ! command -v ovftool > /dev/null; then
    echo "ERROR: unable to locate 'ovftool'. Please define in environment variable OVF_TOOL_ENV or add it to PATH."
    exit 1
  fi

  echo "INFO: using 'ovftool' found in PATH"
  OVF_TOOL=ovftool
}

validateApplianceImage() {
  if [ ! -f "$ONMS_APPLIANCE_IMAGE_FILE" ]; then
    echo "ERROR: appliance image not found: '$ONMS_APPLIANCE_IMAGE_FILE'"
    exit 1
  fi

  echo "INFO: using appliance image: '$ONMS_APPLIANCE_IMAGE_FILE'"
}

validateAndSetApplianceConfig() {
  if [ ! -f "$ONMS_APPLIANCE_CONFIG_FILE" ]; then
    echo "ERROR: appliance configuration file not found: '$ONMS_APPLIANCE_CONFIG_FILE'"
    exit 1
  fi

  echo "INFO: using appliance config: '$ONMS_APPLIANCE_CONFIG_FILE'"

  ONMS_OPT_CLOUD_CONNECT=$(jq -r '.cloudConnect // empty' "$ONMS_APPLIANCE_CONFIG_FILE")
  if [ -z "$ONMS_OPT_CLOUD_CONNECT" ]; then
    echo "ERROR: mandatory config 'cloudConnect' not found in '$ONMS_APPLIANCE_CONFIG_FILE'"
    exit 1
  fi

  ONMS_OPT_NETWORK=$(jq -r '.network // empty' "$ONMS_APPLIANCE_CONFIG_FILE")
  ONMS_OPT_HOSTNAME=$(jq -r '.hostname // empty' "$ONMS_APPLIANCE_CONFIG_FILE")
  ONMS_OPT_HTTP_PROXY=$(jq -r '.httpProxy // empty' "$ONMS_APPLIANCE_CONFIG_FILE")
  ONMS_OPT_HTTPS_PROXY=$(jq -r '.httpsProxy // empty' "$ONMS_APPLIANCE_CONFIG_FILE")
}

validateVmwareConfig() {
  if [ ! -f "$ONMS_OPT_VMWARE" ]; then
    echo "ERROR: VMware configuration file not found: '$ONMS_OPT_VMWARE'"
    exit 1
  fi

  # shellcheck source=/dev/null
  . "$ONMS_OPT_VMWARE"

  if [ -z "$VCENTER_IP" ]; then
    echo "ERROR: vCenter IP (or hostname) not provided"
    exit 1
  fi

  if [ -z "$VMWARE_DATACENTER" ]; then
    echo "ERROR: VMware datacenter not provided"
    exit 1
  fi

  if [ -z "$VMWARE_CLUSTER" ] && [ -z "$VMWARE_HOST" ]; then
    echo "ERROR: either VMware host or cluster must be provided"
    exit 1
  fi

  if [ -z "$VMWARE_NETWORK" ]; then
    echo "ERROR: VMware network not provided"
    exit 1
  fi

  if [ -z "$VMWARE_DATASTORE" ]; then
    echo "ERROR: VMware datastore not provided"
    exit 1
  fi
}

help() {
   cat << EOF
A utility to deploy the OpenNMS appliance to a VMWare vCenter based deployment.
Leverages 'ovftool'; which must be defined in environment variable OVF_TOOL_ENV or set in PATH.

Usage: $(basename "$0") [-c <path>] [-i <path>] [-h]
where:
  -c  Path to the appliance configuration file
  -i  Path to the appliance image
  -w  Path to VMware configuration file
  -h  Shows this help
EOF
}

#
# Main
#

while getopts ":c:i:w:h" arg; do
  case "$arg" in
    h)
      help
      exit 0
      ;;
    c)
      ONMS_APPLIANCE_CONFIG_FILE="$OPTARG"
      ;;
    i)
      ONMS_APPLIANCE_IMAGE_FILE="$OPTARG"
      ;;
    w)
      ONMS_OPT_VMWARE="$OPTARG"
      ;;
    *)
      help
      exit 1
      ;;
  esac
done

requireJq
requireOvfTool
validateApplianceImage
validateAndSetApplianceConfig
validateVmwareConfig

LOCATOR=""
if [ -n "$VMWARE_CLUSTER" ]; then
  LOCATOR="vi://$VCENTER_IP/$VMWARE_DATACENTER/host/$VMWARE_CLUSTER"
else
  LOCATOR="vi://$VCENTER_IP/$VMWARE_DATACENTER/host/$VMWARE_HOST"
fi

# TODO: "diskMode" should likely be "thick"...
# Note: the following prompts for vSphere username and password.
"$OVF_TOOL" \
  --name='OpenNMS Virtual Appliance' \
  --acceptAllEulas \
  --noSSLVerify \
  --datastore="$VMWARE_DATASTORE" \
  --diskMode=thin \
  --net:"Network 1=$VMWARE_NETWORK" \
  --allowExtraConfig \
  --extraConfig:guestinfo.onms.cloudconnect="$ONMS_OPT_CLOUD_CONNECT" \
  --extraConfig:guestinfo.onms.networksettings="$ONMS_OPT_NETWORK" \
  --extraConfig:guestinfo.onms.hostname="$ONMS_OPT_HOSTNAME" \
  --extraConfig:guestinfo.onms.proxy.http="$ONMS_OPT_HTTP_PROXY" \
  --extraConfig:guestinfo.onms.proxy.https="$ONMS_OPT_HTTPS_PROXY" \
  --powerOn \
  "$ONMS_APPLIANCE_IMAGE_FILE" \
  "$LOCATOR"
