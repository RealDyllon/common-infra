# Existing Hetzner VM + k3s Bootstrap Runbook

> This workflow **does not create or destroy Hetzner infrastructure**. Terraform is used only as a remote bootstrap orchestrator for an already-running host.

## Prerequisites

- Existing Hetzner VM already running and reachable by SSH
- SSH key-based admin access to that VM (non-root sudo user recommended)
- Terraform `>= 1.6`
- `make`
- `scp` and `ssh`

## Required environment variables

```bash
export TF_VAR_server_ip="<existing_server_public_ip_or_dns>"
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

## Baseline host hardening (cloud-init template)

Use `cloud-init/k3s-node.yaml.tftpl` as a reference for first-boot hardening on future hosts:
- create non-root admin user
- enforce SSH key-only auth
- install baseline packages
- enable unattended-upgrades

For an already-running VM, apply equivalent SSH hardening manually before bootstrap.

## End-to-end bootstrap (existing host)

1. Initialize plugins:
   ```bash
   make init
   ```
2. Preview actions (file upload + remote install command only):
   ```bash
   make plan TF_VARS_FILE=terraform.tfvars
   ```
3. Install/upgrade k3s on the existing VM:
   ```bash
   make apply TF_VARS_FILE=terraform.tfvars
   ```
4. Pull kubeconfig for local `kubectl`:
   ```bash
   make kubeconfig SSH_PRIVATE_KEY=~/.ssh/id_ed25519
   export KUBECONFIG=.artifacts/kubeconfig
   kubectl get nodes -o wide
   ```

## Recovery / re-run

- Re-run bootstrap installer on the same host:
  ```bash
  terraform -chdir=terraform/hetzner taint null_resource.install_k3s
  make apply
  ```
- Check service state:
  ```bash
  ssh ops@<server_ip> 'sudo systemctl status k3s --no-pager'
  ```

## Destroy behavior

```bash
make destroy TF_VARS_FILE=terraform.tfvars
```

Because no Hetzner infra resources are managed, destroy only removes Terraform state for the bootstrap `null_resource` and does not delete your VM.
