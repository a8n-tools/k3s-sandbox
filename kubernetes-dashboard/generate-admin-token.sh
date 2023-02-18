#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}" || exit 0

# Generate an admin token
kubectl -n kubernetes-dashboard create token admin-user > ./admin-user-token.key

