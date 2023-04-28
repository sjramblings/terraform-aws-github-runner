init:
	terraform init -backend-config="terraform_state.tfvars" -upgrade

validate:
	terraform fmt -recursive
	terraform validate

plan:
	terraform validate
	terraform plan -var-file="variables.tfvars"

apply:
	terraform apply -input=false -var-file="variables.tfvars"

all: validate plan apply

