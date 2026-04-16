# Infrastructure CI and local validation

This repository includes a pull-request CI workflow at `.github/workflows/infra-ci.yml` that runs Terraform and IaC static checks against `terraform/hetzner`.

## CI checks

For each pull request that touches infrastructure-related files, CI runs:

1. `terraform fmt -check -recursive`
2. `terraform validate`
3. `terraform plan` in non-apply safe mode (`-lock=false -refresh=false`) with test values from `terraform/hetzner/ci.tfvars`
4. `tflint`
5. `checkov`

## Required and optional repository secrets

Store credentials in encrypted repository (or organization) secrets and reference them from GitHub Actions. Do **not** commit credentials in code or tfvars files.

- `TF_TOKEN_APP_TERRAFORM_IO` (optional): API token for Terraform private registry/module downloads.

If your Terraform setup later needs provider or cloud credentials, add them as additional GitHub encrypted secrets (for example `HCLOUD_TOKEN`) and pass them through workflow `env`.

## Local developer setup

Install the following tools locally:

- Terraform (>= 1.6)
- tflint
- checkov

Then run:

```bash
make lint-infra
make validate-infra
make plan-infra TF_PLAN_VARS_FILE=ci.tfvars
```

### Notes on planning safely

- `plan-infra` runs `terraform plan` with `-lock=false -refresh=false` to avoid state locking and remote refresh side effects.
- `terraform/hetzner/ci.tfvars` contains mock/test values and is safe for non-apply CI planning.
