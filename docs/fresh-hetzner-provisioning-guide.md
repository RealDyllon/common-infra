# Provisioning a Fresh Hetzner Instance for `common-infra`

This guide shows how to prepare a **new** Hetzner server so it can be bootstrapped by this repository.

> Important: this repository does **not** currently create Hetzner resources (server/network/firewall) with Terraform. It only bootstraps k3s on an already-existing host via SSH.

## Overview

You will do this in two phases:

1. Provision a fresh server in Hetzner (console or API/CLI).
2. Bootstrap k3s onto that host using this repo (`make init/plan/apply`).

## Prerequisites

- Hetzner Cloud project and API token (if using CLI/API)
- Local SSH keypair (for admin access)
- `terraform >= 1.6`
- `make`, `ssh`, `scp`
- Optional: `hcloud` CLI

## Phase 1: Create a fresh Hetzner server

You can use either the Hetzner Cloud Console or `hcloud` CLI.

### Option A: Hetzner Cloud Console

1. Create a new server (Ubuntu/Debian recommended).
2. Select region and server type.
3. Attach your SSH public key.
4. Ensure the instance receives a public IPv4 address.
5. Note the public IP address.

### Option B: `hcloud` CLI (example)

```bash
# one-time auth
hcloud context create common-infra

# create server
hcloud server create \
  --name k3s-1 \
  --type cax11 \
  --image ubuntu-24.04 \
  --location fsn1 \
  --ssh-key <your-ssh-key-name>

# get public IPv4
hcloud server describe k3s-1
```

## Optional first-boot hardening with cloud-init

This repo includes a cloud-init template at `cloud-init/k3s-node.yaml.tftpl` you can use as a baseline for:

- non-root admin user setup
- key-only SSH authentication
- baseline packages and unattended upgrades

If you do not use cloud-init at creation time, apply equivalent hardening manually before running bootstrap.

## Phase 2: Bootstrap k3s with this repository

Set required environment variables:

```bash
export TF_VAR_server_ip="<fresh_server_public_ip>"
export TF_VAR_admin_username="ops"
export TF_VAR_admin_private_key_path="$HOME/.ssh/id_ed25519"
export TF_VAR_k3s_token="<strong_cluster_secret>"
```

Optional overrides:

```bash
export TF_VAR_k3s_version="v1.31.5+k3s1"
export TF_VAR_disable_traefik=true
export TF_VAR_kubeconfig_mode="0640"
```

Run bootstrap:

```bash
make init
make plan TF_VARS_FILE=terraform.tfvars
make apply TF_VARS_FILE=terraform.tfvars
```

Fetch kubeconfig and verify cluster access:

```bash
make kubeconfig SSH_PRIVATE_KEY=~/.ssh/id_ed25519
export KUBECONFIG=.artifacts/kubeconfig
kubectl get nodes -o wide
```

## Re-run / repair bootstrap

To force re-run of the installer on the same host:

```bash
terraform -chdir=terraform/hetzner taint null_resource.install_k3s
make apply
```

Check service health:

```bash
ssh ops@<server_ip> 'sudo systemctl status k3s --no-pager'
```

## Destroy semantics (important)

`make destroy TF_VARS_FILE=terraform.tfvars` only removes Terraform state for bootstrap resources in this repo. It does **not** delete your Hetzner server.

## Recommended follow-up

After bootstrap succeeds:

1. Store kubeconfig securely.
2. Deploy workloads from app-specific repos (Helm/manifests).
3. Add backups, monitoring, and alerting.
4. Consider GitOps (Argo CD/Flux) for ongoing app delivery.
