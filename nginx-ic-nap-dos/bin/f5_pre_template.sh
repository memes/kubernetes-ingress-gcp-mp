#!/bin/bash
#
# Script to be run just ahead of helm template expansion.

set -eox pipefail

DOS_ARBITRATOR_CHART="$1"/charts/nginx-appprotect-dos-arbitrator

error()
{
    echo "$0: ERROR: $*" >&2
    exit 1
}

get_customer_bool()
{
    /bin/yq --exit-status "$1" <(/bin/print_config.py --output=yaml) > /dev/null 2>/dev/null
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

# Remove DoS arbitrator chart if it exists and the user has explicitly disabled it.
if test -d "${DOS_ARBITRATOR_CHART}" && ! get_customer_bool .installDoSArbitrator; then
    rm -rf "${DOS_ARBITRATOR_CHART}" || error "Failed to delete files in ${DOS_ARBITRATOR_CHART}; exit code: $?"
fi
