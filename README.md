# **usp-terraform-infra**
Repositório "Infrastructure-As-Code", IaC terraform.

### **workspaces**  
develop
homolog
production


terraform init -backend-config="access_key=ACCKEY" -backend-config="secret_key=SECKEY"  
terraform plan --var-file ./infra/envs/dev/terraform.tfvars


aws eks update-kubeconfig --region us-east-1 --name usp-cluster --profile usp-adm  

kubectl get svc
kubectl config get-contexts
kubectl config set-context usp-cluster --namespace frontend

kubectl create namespace frontend
kubectl get namespace