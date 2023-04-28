init:
	terraform init -backend-config="terraform_state.tfvars" -upgrade

validate:
	terraform fmt -recursive
	terraform validate

plan:
	terraform validate
	terraform plan

graph:
	terraform graph

apply:
	terraform apply -input=false 

refresh:
	terraform apply -input=false  -refresh-only

destroy:
	terraform destroy -input=false 

list:
	terraform state list 

all: validate plan apply

