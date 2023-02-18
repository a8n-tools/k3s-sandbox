#!/usr/bin/env bash

#SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)
cd "${BASE_DIR}" || exit 0

# Export the secrets into the environment
# shellcheck disable=SC2046
export $(grep -vE "^(#.*|\s*)$" .env)

# Create the CRDs
./cert-manager/create-crds.sh
./traefik/create-crds.sh
