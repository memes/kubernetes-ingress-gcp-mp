#!/bin/bash
#
# Script to be run just ahead of helm template expansion.

set -eox pipefail

error()
{
    echo "$0: ERROR: $*" >&2
    exit 1
}

# Replace placeholder values in /data/chart/values.yaml
REPORTING_SECRET="$(/bin/print_config.py --xtype REPORTING_SECRET --values_mode raw)"
/bin/yq -i ".nginx-ingress.controller.extraContainers[0].env[0].valueFrom.secretKeyRef.name |= \"${REPORTING_SECRET}\"" "$1"/values.yaml || \
    error "Failed to update reporting secret name"
/bin/yq -i ".nginx-ingress.controller.extraContainers[0].env[1].valueFrom.secretKeyRef.name |= \"${REPORTING_SECRET}\"" "$1"/values.yaml || \
    error "Failed to update reporting secret name"
UBB_IMAGE="$(/bin/yq '.ubbAgentImage' <(/bin/print_config.py --output=yaml))"
/bin/yq -i ".nginx-ingress.controller.extraContainers[0].image |= \"${UBB_IMAGE}\"" "$1"/values.yaml || \
    error "Failed to update placeholder UBB Agent image"
