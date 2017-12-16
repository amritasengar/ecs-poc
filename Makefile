validate:
		terraform init
		terraform validate -var-file terraform.tfvars

plan:
		terraform init
		terraform plan -var-file terraform.tfvars

apply:
		terraform apply -var-file terraform.tfvars -auto-approve

destroy:
		terraform destroy
