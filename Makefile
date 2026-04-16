TERRAFORM_DIR ?= terraform/hetzner
TF ?= terraform
TF_VARS_FILE ?= terraform.tfvars
TF_PLAN_VARS_FILE ?= $(TF_VARS_FILE)
KUBECONFIG_OUT ?= .artifacts/kubeconfig
SSH_PRIVATE_KEY ?= ~/.ssh/id_ed25519

.PHONY: init plan apply destroy kubeconfig lint-infra validate-infra plan-infra

init:
	$(TF) -chdir=$(TERRAFORM_DIR) init

plan:
	$(TF) -chdir=$(TERRAFORM_DIR) plan -var-file=$(TF_VARS_FILE)

apply:
	$(TF) -chdir=$(TERRAFORM_DIR) apply -var-file=$(TF_VARS_FILE)

destroy:
	$(TF) -chdir=$(TERRAFORM_DIR) destroy -var-file=$(TF_VARS_FILE)

lint-infra:
	$(TF) -chdir=$(TERRAFORM_DIR) fmt -check -recursive
	tflint --chdir $(TERRAFORM_DIR)
	checkov --directory $(TERRAFORM_DIR) --quiet

validate-infra:
	$(TF) -chdir=$(TERRAFORM_DIR) init -backend=false
	$(TF) -chdir=$(TERRAFORM_DIR) validate

plan-infra:
	$(TF) -chdir=$(TERRAFORM_DIR) init -backend=false
	$(TF) -chdir=$(TERRAFORM_DIR) plan -input=false -lock=false -refresh=false -var-file=$(TF_PLAN_VARS_FILE)

kubeconfig:
	mkdir -p $(dir $(KUBECONFIG_OUT))
	@SERVER_IP=$$($(TF) -chdir=$(TERRAFORM_DIR) output -raw k3s_endpoint); \
	ADMIN_USER=$$($(TF) -chdir=$(TERRAFORM_DIR) output -raw admin_username); \
	scp -o StrictHostKeyChecking=accept-new -i $(SSH_PRIVATE_KEY) $$ADMIN_USER@$$SERVER_IP:/etc/rancher/k3s/k3s.yaml $(KUBECONFIG_OUT); \
	sed -i "s/127.0.0.1/$$SERVER_IP/" $(KUBECONFIG_OUT); \
	chmod 600 $(KUBECONFIG_OUT); \
	echo "Kubeconfig written to $(KUBECONFIG_OUT)"
