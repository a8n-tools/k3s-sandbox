#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}" || exit 0

# Helm requires apparmor
# https://github.com/rancher/k3os/issues/702#issuecomment-865477845
#zypper install apparmor-parser

#	--dry-run
#	--debug
helm install \
	kube-prometheus-stack \
	prometheus-community/kube-prometheus-stack
