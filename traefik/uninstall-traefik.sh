#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}" || exit 0

# helm ls --all-namespaces
helm --namespace traefik delete traefik-nebula
kubectl delete namespace traefik
