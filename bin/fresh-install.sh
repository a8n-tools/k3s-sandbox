#!/usr/bin/env bash

#SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)
cd "${BASE_DIR}" || exit 0

# Export the secrets into the environment
# shellcheck disable=SC2046
export $(grep -vE "^(#.*|\s*)$" .env)

# which checks that the file is executable.
if which k3s-uninstall.sh 2>/dev/null; then
	echo "Uninstalling k3s"
	sudo /usr/local/bin/k3s-uninstall.sh
fi

# Masquerade is required for the pods to reach the internet.
# dial tcp: lookup acme-staging-v02.api.letsencrypt.org on 1.1.1.1:53: read udp 10.42.0.12:48704->1.1.1.1:53: read: no route to host
if sudo firewall-cmd --info-zone public | grep --quiet 'masquerade: no'; then
	sudo firewall-cmd --zone public --add-masquerade
	sudo firewall-cmd --runtime-to-permanent
fi
sudo firewall-cmd --info-zone public

# Check if ~/.kube exists
# Need to specify /root/.kube because ~/ expands to the user's home directory, not root's home directory.
[ ! -d /root/.kube ] && echo "Making /root/.kube" && mkdir /root/.kube

# Flannel backend options: https://docs.k3s.io/installation/network-options#flannel-options
#	--k3s-extra-args "--advertise-address=${K3S_ADMIN_IP} --bind-address=${K3S_ADMIN_IP} --tls-san=${K3S_ADMIN_IP} --flannel-backend=host-gw --node-ip=${K3S_ADMIN_IP} --flannel-iface=${K3S_ADMIN_IFACE}"
sudo k3sup install \
	--local \
	--local-path /root/.kube/config \
	--k3s-channel latest \
	--k3s-extra-args "--advertise-address=${K3S_ADMIN_IP} --bind-address=${K3S_ADMIN_IP} --tls-san=${K3S_ADMIN_IP}"

export KUBECONFIG=/root/.kube/config
sudo --preserve-env kubectl get node -o wide

echo "Copy /root/.kube/config to your local machine to access the cluster remotely."
