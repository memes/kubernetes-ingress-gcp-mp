#!/bin/bash
#
# Script to be run just ahead of kubectl apply of expanded helm template. The
# directory containing the expanded helm chart must be supplied as first argumemnt.

set -eox pipefail

INGRESS_CRDS="$1/charts/nginx-ingress/crds"

error()
{
    echo "$0: ERROR: $*" >&2
    exit 1
}

# Returns true if the key exists and is truthy in the values provided by GCP marketplace,
# false if key is missing or set to a false value.
get_customer_bool()
{
    /bin/yq --exit-status "$1" <(/bin/print_config.py --output=yaml) > /dev/null 2>/dev/null
}

test -d "${INGRESS_CRDS}" || error "Missing ${INGRESS_CRDS}"

# Install base CRDs
for crd in "${INGRESS_CRDS}"/k8s.nginx.org_[!g]*.yaml ; do
    kubectl apply -f "${crd}" --validate=false || error "Failed to apply ${crd}"
done

# Install global configuration CRD? Default in upstream chart is false, so only
# apply if the customer has opted in.
if get_customer_bool '.nginx-ingress.controller.globalConfiguration.create'; then
    kubectl apply -f "${INGRESS_CRDS}/k8s.nginx.org_globalconfigurations.yaml" --validate=false || \
        error "Failed to apply ${INGRESS_CRDS}/k8s.nginx.org_globalconfigurations.yaml"
fi

# Install app protect and app protect DoS CRDs
for crd in "${INGRESS_CRDS}"/appprotect.f5.com_*.yaml "${INGRESS_CRDS}"/appprotectdos.f5.com_*.yaml ; do
    kubectl apply -f "${crd}" --validate=false || error "Failed to apply ${crd}"
done

# Install ExternalDNS CRDs? Default in upstream chart is false, so only
# apply if the customer has opted in.
if get_customer_bool '.nginx-ingress.controller.enableExternalDNS'; then
    for crd in "${INGRESS_CRDS}"/externaldns.nginx.org_*.yaml ; do
        kubectl apply -f "${crd}" --validate=false || error "Failed to apply ${crd}"
    done
fi
