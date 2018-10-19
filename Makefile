.PHONY: plan apply

# Use `make plan` to see how your changes will affect
# our infrastructure when applied. We use Landscape
# to make the diff easier to read, and quickly re-init
# in case we need to initialize modules or plugins.
plan:
	terraform init --backend=false
	terraform plan | landscape

# Use `make apply` to update infrastructure based on
# the local Terraform config.
apply:
	terraform apply
