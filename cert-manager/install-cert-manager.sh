#!/usr/bin/env bash

#BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}" || exit 0

# Note: installCRDs=true does not work. Need to apply them separately.
GITHUB_URL=https://github.com/cert-manager/cert-manager/releases
LATEST_VERSION=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
kubectl apply --filename "https://github.com/cert-manager/cert-manager/releases/download/${LATEST_VERSION}/cert-manager.crds.yaml"

# Create the namespace if it doesn't exist
NAMESPACE=cert-manager
if ! kubectl get namespaces | grep --quiet "^$NAMESPACE"
then
	echo "Creating namespace ${NAMESPACE}"
	kubectl create namespace $NAMESPACE
fi
kubectl get namespaces

# https://artifacthub.io/packages/helm/cert-manager/cert-manager
# helm install [NAME] [CHART] [flags]
#	--dry-run \
#	--debug \
# FIXME: Does $CLOUDFLARE_DNS_SERVERS require a backslash before the comma? (in .env)
helm install \
	--namespace $NAMESPACE \
	--values values.yml \
	--set extraArgs="{--dns01-recursive-nameservers-only,--dns01-recursive-nameservers=$CLOUDFLARE_DNS_SERVERS}" \
	cert-manager \
	jetstack/cert-manager
