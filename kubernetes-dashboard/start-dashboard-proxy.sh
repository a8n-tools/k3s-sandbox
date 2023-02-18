#!/usr/bin/env bash

#SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)
cd "${BASE_DIR}" || exit 0

# Export the secrets into the environment
# shellcheck disable=SC2046
#export $(grep -vE "^(#.*|\s*)$" .env)

POD_NAME=$(kubectl get pods -n kubernetes-dashboard -l "app.kubernetes.io/name=kubernetes-dashboard,app.kubernetes.io/instance=kubernetes-dashboard" -o jsonpath="{.items[0].metadata.name}")
export POD_NAME
echo https://127.0.0.1:8443/
kubectl --namespace kubernetes-dashboard port-forward "${POD_NAME}" 8443:8443
