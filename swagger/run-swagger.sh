#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}" || exit 0

export PORT=8001
#kubectl proxy --port "${PORT}"
curl "localhost:${PORT}/openapi/v2" > k8s-swagger.json

# https://jonnylangefeld.com/blog/kubernetes-how-to-view-swagger-ui

echo "openapi will be available at this link"
echo "http://localhost:${PORT}/openapi/v2"
echo

docker run \
	--rm \
	--publish "12080:${PORT}" \
	--env SWAGGER_JSON=/k8s-swagger.json \
	--volume "${PWD}/k8s-swagger.json:/k8s-swagger.json" \
	swaggerapi/swagger-ui
