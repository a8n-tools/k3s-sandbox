#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}" || exit 0

#	--dry-run
#	--debug
helm install \
	adguard-home \
	k8s-at-home-charts/adguard-home \
	-f values.yml

export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=adguard-home,app.kubernetes.io/instance=adguard-home" -o jsonpath="{.items[0].metadata.name}")
echo "Visit http://127.0.0.1:8080 to use your application"
kubectl port-forward $POD_NAME 8080:3000
