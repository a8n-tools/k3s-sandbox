#!/usr/bin/env bash

# Add all the helm repos so they don't have to be added/managed individually.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}" || exit 0

# Helm requires apparmor
# https://github.com/rancher/k3os/issues/702#issuecomment-865477845
#zypper install apparmor-parser

# https://github.com/cert-manager/cert-manager
helm repo add jetstack https://charts.jetstack.io

# https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# https://github.com/kubernetes/dashboard
# https://artifacthub.io/packages/helm/k8s-dashboard/kubernetes-dashboard
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/

# https://github.com/traefik/traefik-helm-chart
helm repo add traefik https://helm.traefik.io/traefik

helm repo update
