# Use helm from GCP Marketplace container to bring in dependent charts from
# upstream repo and convert to tarball
FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm:0.11.7 as charts
RUN apt-get update && \
    apt-get install -y --no-install-recommends gettext curl && \
    curl -sLo /bin/yq https://github.com/mikefarah/yq/releases/download/v4.30.6/yq_linux_amd64 && \
    chmod 0755 /bin/yq

# Bring in the GCP Marketplace schema declarations and charts, update helm
# dependencies, flatten, then transform to the tarball needed by deployer_helm.
COPY schema.yaml /tmp/
COPY apptest/schema.yaml /tmp/test/
COPY chart /tmp/chart/
COPY apptest/chart /tmp/test/chart/
RUN helm repo add nginx-ingress https://helm.nginx.com/stable && \
    helm dependency update /tmp/chart && \
    tar -xzf /tmp/chart/charts/nginx-ingress-*.tgz -C /tmp/chart/charts && \
    rm -f /tmp/chart/charts/nginx-ingress-*.tgz && \
    tar -czf /tmp/nginx-ingress.tar.gz -C /tmp/ chart && \
    tar -czf /tmp/test/nginx-ingress.tar.gz -C /tmp/test/ chart/

# Package up the final deployer image from GCP Marketplace helm deployer
FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm:0.11.7
# Handle CRD installation by patching GCP deployer to call shell scripts
COPY --from=charts /bin/yq /bin/yq
COPY bin/f5_pre_apply.sh /bin/
RUN chmod 0755 /bin/f5_pre_apply.sh && \
    sed -i '/^kubectl apply --namespace/i/bin/f5_pre_apply.sh /data/extracted/nginx-ingress/chart\n' /bin/deploy.sh /bin/deploy_with_tests.sh
# Add the bundled deployer and tester charts and schemas
COPY --from=charts /tmp/test/nginx-ingress.tar.gz /data-test/chart/
COPY --from=charts /tmp/test/schema.yaml /data-test/
COPY --from=charts /tmp/nginx-ingress.tar.gz /data/chart/
COPY --from=charts /tmp/schema.yaml /data/
