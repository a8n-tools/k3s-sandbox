#!/usr/bin/env bash

#BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}" || exit 0

# Create the namespace if it doesn't exist
NAMESPACE=traefik
if ! kubectl get namespaces | grep --quiet "^$NAMESPACE"
then
	echo "Creating namespace ${NAMESPACE}"
	kubectl create namespace $NAMESPACE
fi
kubectl get namespaces

# Traefik doesn't need to be installed because k3s provides the traefik.io/ingress-controller as part of the base
# install.
## The "traefik" NAME conflicts with the traefik NAME installed by k3s.
# helm install [NAME] [CHART] [flags]
#	--dry-run
#	--debug
#helm install \
#	--namespace $NAMESPACE \
#	--values values.yml \
#	traefik-custom \
#	traefik/traefik
