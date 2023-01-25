#!/bin/bash
#
# Script to be run just ahead of helm template expansion.

set -eox pipefail

DOS_ARBITRATOR_CHART=$1/charts/nginx-appprotect-dos-arbitrator

error()
{
    echo "$0: ERROR: $*" >&2
    exit 1
}

get_customer_bool()
{
    /bin/yq --exit-status "$1" <(/bin/print_config.py --output=yaml) > /dev/null 2>/dev/null
}

# Remove DoS arbitrator chart if it exists and the user has explicitly disabled it.
if test -d "${DOS_ARBITRATOR_CHART}" && ! get_customer_bool .installDoSArbitrator; then
    rm -rf "${DOS_ARBITRATOR_CHART}" || error "Failed to delete files in ${DOS_ARBITRATOR_CHART}; exit code: $?"
fi
