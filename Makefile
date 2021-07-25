.PHONY: tools terraform-init terraform-validate terraform-plan terraform-apply terraform-destroy service-check

tools:
	@echo "Installing Terraform"
	@brew tap hashicorp/tap
	@brew install hashicorp/tap/terraform

terraform-init:
	@echo "\n*Initializing Terraform environment*\n"
	@cd terraform && terraform init

terraform-validate: terraform-init
	@echo "\n*Validating Terraform syntax*\n"
	@cd terraform && terraform validate

terraform-plan: terraform-init
	@echo "\n*Generating binary Terraform plan*\n"
	@cd terraform && terraform plan -var-file=main.tfvars -out=terraform-plan

terraform-apply: terraform-plan
	@echo "\n*Applying binary Terraform plan*\n"
	@cd terraform && terraform apply terraform-plan && rm terraform-plan

terraform-destroy:
	@echo "\n*Tearing things down*\n"
	@cd terraform && terraform destroy -var-file=main.tfvars

service-check:
	@./service-check.sh $(url)