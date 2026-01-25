.PHONY: terraform-apply
terraform-apply:
	@bash -c 'source .env && terraform apply -auto-approve'

.PHONY: terraform-destroy
terraform-destroy:
	@bash -c 'source .env && terraform destroy -auto-approve'

.PHONY: terraform-plan
terraform-plan:
	@bash -c 'source .env && terraform plan'

.PHONY: terraform-init
terraform-init:
	@terraform init
