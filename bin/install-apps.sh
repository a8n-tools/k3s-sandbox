#!/usr/bin/env bash

#SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)
cd "${BASE_DIR}" || exit 0

# Export the secrets into the environment
# shellcheck disable=SC2046
export $(grep -vE "^(#.*|\s*)$" .env)

# Copy the kube config so we can manage the cluster remotely
scp "root@${K3S_ADMIN_HOSTNAME}:.kube/config" ~/.kube/config

# Install the dashboard
./kubernetes-dashboard/install-dashboard.sh

# Install traefik
# This really just creates a "traefik" namespace to hold Traefik specific CRDs.
./traefik/install-traefik.sh

# Install cert-manager
./cert-manager/install-cert-manager.sh
