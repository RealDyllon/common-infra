# common-infra

Infrastructure bootstrap repository for provisioning k3s on an **existing** server over SSH.

> This repository does **not** create or destroy Hetzner cloud resources. It uses Terraform as a bootstrap orchestrator to install/upgrade k3s on a host you already created.

## What this repo does

- Bootstraps k3s onto an existing host using Terraform + SSH provisioners
- Provides Makefile commands for infra workflow (`init`, `plan`, `apply`, `destroy`)
- Fetches kubeconfig locally for cluster access
- Runs infra validation and static checks in CI (`fmt`, `validate`, `plan`, `tflint`, `checkov`)

## Repository layout

- `terraform/hetzner/` — Terraform bootstrap module for remote k3s install
- `scripts/install-k3s.sh` — k3s installer invoked remotely by Terraform
- `cloud-init/` — baseline hardening template for future hosts
- `docs/` — operational guides and CI documentation

## Quick start

### 1) Set required environment variables

```bash
export TF_VAR_server_ip="<existing_server_public_ip_or_dns>"
export TF_VAR_admin_username="ops"
export TF_VAR_admin_private_key_path="$HOME/.ssh/id_ed25519"
export TF_VAR_k3s_token="<strong_cluster_secret>"
```

### 2) Bootstrap k3s

```bash
make init
make plan TF_VARS_FILE=terraform.tfvars
make apply TF_VARS_FILE=terraform.tfvars
```

### 3) Pull kubeconfig

```bash
make kubeconfig SSH_PRIVATE_KEY=~/.ssh/id_ed25519
export KUBECONFIG=.artifacts/kubeconfig
kubectl get nodes -o wide
```

## Make targets

- `make init` — initialize Terraform
- `make plan` — preview bootstrap actions
- `make apply` — run bootstrap actions
- `make destroy` — remove Terraform state for bootstrap resources (does not delete VM)
- `make kubeconfig` — download and rewrite kubeconfig endpoint to server IP
- `make lint-infra` — fmt/tflint/checkov checks
- `make validate-infra` — terraform validate
- `make plan-infra` — safe CI-style plan (`-lock=false -refresh=false`)

## Guides

- [App Repo + Common Infra Integration Guide](docs/app-repo-integration-guide.md)
- [Fresh Hetzner Provisioning Guide](docs/fresh-hetzner-provisioning-guide.md)
- [Existing Hetzner VM + k3s Bootstrap Runbook](docs/hetzner-k3s-bootstrap.md)
- [Infrastructure CI and local validation](docs/infra-ci.md)

## Notes

- Keep credentials in environment variables or secret stores, not committed files.
- Use app-specific repositories to build/push images and deploy workloads (Helm/manifests).
