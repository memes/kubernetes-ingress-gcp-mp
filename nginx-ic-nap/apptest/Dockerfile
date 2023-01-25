FROM gcr.io/cloud-marketplace-tools/testrunner:0.1.4

# Update CA certificates and install curl
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

# This should match the kubernetes minor version that would be provisioned as a
# "stable" channel in GKE as that should be compatible with most "regular" and
# "rapid" channels. Currently that is 1.23.x
# See https://kubernetes.io/releases/version-skew-policy/#kubectl
ARG KUBECTL_VERSION=v1.23.13
RUN curl -sLo /bin/kubectl https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
    && chmod 0755 /bin/kubectl

# Copy the test-suite to validate
COPY tests /run/tests/
COPY bin/tester.sh /run/tester.sh
WORKDIR /run/tests
USER nobody
ENTRYPOINT [ "/bin/bash", "/run/tester.sh" ]
