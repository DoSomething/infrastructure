.PHONY: help init format plan apply

BOLD=$(shell tput bold)
RED=$(shell tput setaf 1)
RESET=$(shell tput sgr0)

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform, on first-use or when adding modules or plugins.
	@echo "$(BOLD)Configuring git hooks...$(RESET)"
	@git config core.hooksPath .githooks
	@cp -n example.terraform.tfvars terraform.tfvars || true
	@terraform init

format: ## Format your code automatically.
	@terraform fmt

plan: ## See how your changes would affect our infrastructure if applied.
	@terraform plan