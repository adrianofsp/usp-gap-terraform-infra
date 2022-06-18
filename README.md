# **usp-terraform-infra**
Repositório "Infrastructure-As-Code", IaC terraform.

### **workspaces**  
develop
homolog
production


terraform init -backend-config="access_key=ACCKEY" -backend-config="secret_key=SECKEY"  
terraform plan --var-file ./infra/envs/dev/terraform.tfvars


aws eks update-kubeconfig --region us-east-1 --name usp-cluster --profile usp-adm