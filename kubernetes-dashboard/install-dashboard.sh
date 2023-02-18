#!/usr/bin/env bash

#BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}" || exit 0

echo "Installing k3s dashboard"
# https://github.com/kubernetes/dashboard/blob/master/charts/helm-chart/kubernetes-dashboard/values.yaml

# Admin dashboard
#GITHUB_URL=https://github.com/kubernetes/dashboard/releases
#LATEST_VERSION=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
#kubectl create --filename "https://raw.githubusercontent.com/kubernetes/dashboard/${LATEST_VERSION}/aio/deploy/recommended.yaml"

# Create the namespace if it doesn't exist
NAMESPACE=kubernetes-dashboard
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
helm install \
	--namespace $NAMESPACE \
	--values values.yml \
	kubernetes-dashboard \
	kubernetes-dashboard/kubernetes-dashboard

kubectl create --filename users/dashboard.admin-user.yml
kubectl create --filename users/dashboard.admin-user-role.yml
kubectl --namespace $NAMESPACE create token admin-user > ./admin-user-token.key

echo
echo "Create a proxy to the dashboard"
echo "kubectl proxy"
echo "Access the proxy at this URL"
echo "http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo "Login using the admin token"
echo "cat admin-user-token.key"
cat admin-user-token.key

echo -e "Done installing k3s dashboard\n\n"
