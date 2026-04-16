#!/usr/bin/env bash
set -euo pipefail

: "${K3S_VERSION:?K3S_VERSION is required}"
: "${K3S_TOKEN:?K3S_TOKEN is required}"
: "${KUBECONFIG_MODE:=0640}"
: "${DISABLE_TRAEFIK:=true}"

export INSTALL_K3S_VERSION="${K3S_VERSION}"

exec_args=(
  "server"
  "--token" "${K3S_TOKEN}"
  "--write-kubeconfig-mode" "${KUBECONFIG_MODE}"
)

if [[ "${DISABLE_TRAEFIK}" == "true" ]]; then
  exec_args+=("--disable" "traefik")
fi

export INSTALL_K3S_EXEC="${exec_args[*]}"

curl -sfL https://get.k3s.io | sh -

systemctl enable --now k3s
