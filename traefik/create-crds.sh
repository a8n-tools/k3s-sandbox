#!/usr/bin/env bash

#BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}" || exit 0

# Generate the basic auth credentials
ADMIN_BASIC_AUTH_BASE64=$(htpasswd -nb "${ADMIN_BASIC_AUTH_USERNAME}" "${ADMIN_BASIC_AUTH_PASSWORD}" | base64)
export ADMIN_BASIC_AUTH_BASE64

# Ingress routes
envsubst < ./ingress-routes/traefik-dashboard-ingress.yml | kubectl apply --filename -
envsubst < ./ingress-routes/k3s-dashboard-ingress.yml | kubectl apply --filename -
