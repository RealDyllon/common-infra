# App Repo + Common Infra Integration Guide

This guide explains how to use this repository (`common-infra`) together with an app-specific repository (for example, `foobar-app`) to deploy workloads onto a k3s cluster.

## What this repo is responsible for

This repository is a **cluster bootstrap/orchestration layer** for an existing host:

- It does **not** create or destroy Hetzner infrastructure.
- It bootstraps k3s onto an already-running server over SSH using Terraform + a remote install script.
- It provides a Makefile workflow for init/plan/apply/destroy and for fetching kubeconfig.

In short: treat this repo as the place to manage the cluster foundation, not app manifests.

## What your app repo is responsible for

Your app-specific repo (for example `foobar-app`) should own:

- Application source code
- Container image build and publishing
- Kubernetes deployment artifacts (Helm chart and/or raw manifests)
- App-level CI/CD pipeline (build, test, deploy)

In short: treat app repos as workload delivery repositories.

## Recommended repo model

Use a two-repo model:

1. **`common-infra`** (this repo)
   - Bootstrap and maintain cluster access
   - Handle base infrastructure checks (Terraform lint/validate/plan)

2. **`foobar-app`** (app repo)
   - Build image for `foobar`
   - Deploy/update Kubernetes resources on the target cluster

## End-to-end deployment flow for `foobar`

### 1) Bootstrap cluster from `common-infra`

Set required Terraform variables (example):

```bash
export TF_VAR_server_ip="<existing_server_public_ip_or_dns>"
export TF_VAR_admin_username="ops"
export TF_VAR_admin_private_key_path="$HOME/.ssh/id_ed25519"
export TF_VAR_k3s_token="<strong_cluster_secret>"
```

Run bootstrap:

```bash
make init
make plan TF_VARS_FILE=terraform.tfvars
make apply TF_VARS_FILE=terraform.tfvars
```

Fetch kubeconfig:

```bash
make kubeconfig SSH_PRIVATE_KEY=~/.ssh/id_ed25519
export KUBECONFIG=.artifacts/kubeconfig
kubectl get nodes -o wide
```

### 2) Deploy app from `foobar-app`

From your app repository, use either:

- `kubectl apply -f k8s/`
- or `helm upgrade --install foobar ./chart -n foobar --create-namespace`

A typical app deployment contains:

- Namespace
- Deployment
- Service
- Ingress (or Gateway API resources)
- ConfigMap/Secret references
- HPA (optional)

## CI/CD suggestion

### In `common-infra`

Keep infra validation (already present in this repo):

- `terraform fmt -check -recursive`
- `terraform validate`
- safe `terraform plan`
- `tflint`
- `checkov`

### In `foobar-app`

Add app pipeline stages:

1. Build and test app
2. Build and push image
3. Deploy manifests/chart to cluster
4. Verify rollout (e.g., `kubectl rollout status`)

## Operational notes

- `make destroy` here only removes Terraform state for bootstrap resources and does **not** delete your existing VM.
- Re-running bootstrap can be done by tainting `null_resource.install_k3s` and applying again.

## Optional next step: GitOps

For stronger separation and auditability, consider GitOps:

- Keep `foobar-app` manifests/charts in git
- Use Argo CD or Flux in-cluster to sync desired state
- Keep `common-infra` focused on cluster lifecycle and access

---

If desired, add a companion guide in `foobar-app` describing required environment variables, image tagging conventions, and deployment commands.
