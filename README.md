# NGINX+ Ingress Controller GCP Marketplace packaging repo

This repository holds the definitions for GCP Marketplace deployer and apptest
containers for the NGINX+ Ingress Controller variants published. These containers
are additional to the main [kubernetes-ingress] packages published by NGINX.

## Dependencies

* NGINX+ Ingress Controller built with GCP support for target variant published
  to the destination container repository, bare semver tagged as `major.minor.patch`
  and `major.minor`.

  E.g. to promote NGINX+ Ingress Controller v2.5.0 to Google Marketplace, containers
  `gcr.io/f5-7626-networks-public/nginxinc/nginx-ingress-plus:2.5.0` and
  `gcr.io/f5-7626-networks-public/nginxinc/nginx-ingress-plus:2.5` must exist.

* Access to NGINX [helm chart repository] to fetch published Helm charts for
  NGINX Ingress Controller and App Protect DoS Arbitrator.

* Access to NGINX private container repository at `docker-registry.nginx.com`
  via JWT key; the example [cloudbuild](/cloudbuild.yaml) declaration copies
  NGINX App Protect Dos Arbitrator containers needed by *w/App Protect DoS* and
  *w/App Protect WAF & DoS* variants.

[kubernetes-ingress]: https://github.com/nginxinc/kubernetes-ingress
[helm chart repository]: https://helm.nginx.com/
