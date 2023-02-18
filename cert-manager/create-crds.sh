#!/usr/bin/env bash

#BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}" || exit 0

# Convert to base64 and remove the original values
CLOUDFLARE_API_EMAIL_BASE64=$(echo -n "$CLOUDFLARE_API_EMAIL" | base64)
CLOUDFLARE_API_TOKEN_BASE64=$(echo -n "$CLOUDFLARE_API_TOKEN" | base64)
export CLOUDFLARE_API_TOKEN_BASE64 CLOUDFLARE_API_EMAIL_BASE64

# Add the credentials
envsubst < ./issuers/base-domain-cloudflare-token-secret.yml | kubectl apply --filename -

# Add the issuer
envsubst < ./issuers/letsencrypt-cloudflare-staging.yml | kubectl apply --filename -
#envsubst < ./issuers/letsencrypt-cloudflare-production.yml | kubectl apply --filename -

# Add the staging certificate first. This starts the process to request the certificate.
kubectl apply --filename "certificates/staging/base-domain.yml"
#kubectl apply --filename "certificates/production/base-domain.yml"
