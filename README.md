# AWS DevOps Project

This project provisions a complete DevOps and Kubernetes environment on AWS using Infrastructure as Code and automation tools. It includes:
- A custom VPC with public subnets (Terraform)
- EC2 instances for Jenkins master, Jenkins build slave, and an Ansible server (Terraform)
- Security groups for secure access (Terraform)
- Automated setup of Jenkins, Java, Maven, Docker, Docker Buildx, kubectl, AWS CLI, Helm, MySQL, Prometheus, Grafana, SonarQube/SonarCloud, JFrog Artifactory, and Shell scripting using Ansible
- An Amazon EKS (Elastic Kubernetes Service) cluster with autoscaling node groups (Terraform)
- Kubernetes cluster management and integration with Jenkins CI/CD pipelines (kubectl, AWS CLI, Jenkins)
- Helm for Kubernetes package management (MySQL, Prometheus, Grafana, application Helm Chart)
- Monitoring stack with Prometheus and Grafana (Helm)
- Static code analysis and quality gates with SonarQube/SonarCloud
- Docker image build and push to JFrog Artifactory
- Kubernetes deployment and autoscaling (HPA) on AWS EKS
- Helm-based templated deployments for repeatability and best practices
- Automated and idempotent configuration for all tools and services
- Prometheus and Grafana are automatically exposed via AWS LoadBalancer services for external access
- Secure configuration and cloud-native deployment patterns
- Shell scripts for automated deployment to Kubernetes clusters
- JUnit 5 for unit testing
- Spring Boot 3.2.6 for REST API development

## Application Repository and CI/CD Pipeline

This infrastructure is designed to deploy and manage the [Automationsaan Hello World Spring Boot Project](https://github.com/automationsaan/hello-world-springboot), a simple Spring Boot REST API with a complete CI/CD pipeline. The application and pipeline demonstrate:
- Automated build, test, and deployment using Jenkins
- Static code analysis and quality gates with SonarQube/SonarCloud
- Docker image build and push to JFrog Artifactory
- Kubernetes deployment and autoscaling on AWS EKS
- Helm-based templated deployments for repeatability and best practices
- Secure configuration and cloud-native deployment patterns

## Tools and Technologies Used

- **Java 21**: Programming language for the application
- **Spring Boot 3.2.6**: REST API framework
- **Maven**: Build automation and dependency management
- **JUnit 5**: Unit testing framework
- **Jenkins**: CI/CD automation server (pipeline defined in Jenkinsfile)
- **SonarQube/SonarCloud**: Static code analysis and quality gate enforcement
- **Docker**: Containerization of the Spring Boot application
- **JFrog Artifactory**: Artifact and Docker image repository
- **Kubernetes (EKS)**: Container orchestration for automated deployment, scaling, and management
- **Amazon EKS (Elastic Kubernetes Service)**: Managed Kubernetes cluster for running production workloads in AWS
- **Kubernetes Autoscaling (HPA)**: Horizontal Pod Autoscaler for automatic scaling based on resource usage
- **Kubernetes YAML Manifests**: Declarative configuration for deployment, service, namespace, and secrets
- **Helm**: Kubernetes package manager for templated, repeatable deployments (see Helm Deploy stage in Jenkinsfile)
- **Helm Chart**: Used for parameterized, production-grade Kubernetes deployments
- **Shell Scripts**: For automated deployment to Kubernetes clusters (see `kubernetes/deploy.sh`)
- **Terraform**: Infrastructure as Code for AWS resources (VPC, subnets, security groups, EC2, EKS, IAM, etc.)
- **Ansible**: Configuration management and automation for provisioning Jenkins, Java, Maven, Docker, Docker Buildx, kubectl, AWS CLI, Helm, MySQL, Prometheus, Grafana
- **Prometheus & Grafana**: Monitoring stack (deployed via kube-prometheus-stack Helm chart, exposed via AWS LoadBalancer)
- **MySQL**: Deployed on Kubernetes using Bitnami Helm chart
- **AWS CLI**: Command-line interface for managing AWS resources and EKS clusters
- **kubectl**: Kubernetes CLI for managing clusters and workloads
- **Docker Buildx & BuildKit**: Advanced Docker build capabilities
- **Bitnami & Prometheus Community Helm Repos**: For production-grade application charts
- **Amazon ECR (optional)**: For container image storage (if used in your pipeline)
- **Ubuntu 22.04+**: Operating system for all instances

---

### Accessing Grafana and Prometheus after Service Type Change

After running the playbook, both Grafana and Prometheus are exposed via AWS LoadBalancer services.

1. Get the external DNS/hostname for each service:
   ```sh
   kubectl get svc -n automationsaan-prom-monitoring
   ```
   Example output:
   ```
   NAME                TYPE           CLUSTER-IP      EXTERNAL-IP                                                               PORT(S)   AGE
   prometheus-grafana  LoadBalancer   172.20.45.167   a766a756a42b943ac99dfb375972f2a1-1304622396.us-west-2.elb.amazonaws.com   80:...   ...
   prometheus-...      LoadBalancer   ...             ...                                                                       9090:...  ...
   ```
2. Access Grafana:
   - http://<EXTERNAL-IP-or-DNS>:80
   - (Default credentials: admin/prom-operator unless overridden)
3. Access Prometheus:
   - http://<EXTERNAL-IP-or-DNS>:9090
4. If you do not see an EXTERNAL-IP immediately, wait a few minutes for AWS to provision the ELB.
5. For security, restrict access to these LoadBalancers using AWS security groups as needed.

---

## Cleaning Up the Jenkins/Maven Slave for a Fresh Playbook Run

To ensure a clean, error-free playbook run, perform the following steps on your Jenkins/Maven slave (or wherever you have kubectl/helm access):

```sh
# Uninstall Helm releases (MySQL, Prometheus/Grafana)
helm uninstall demo-mysql -n automationsaan
helm uninstall prometheus -n automationsaan-prom-monitoring

# Delete Kubernetes namespaces (if you want a full reset)
kubectl delete namespace automationsaan
kubectl delete namespace automationsaan-prom-monitoring

# Remove downloaded Helm chart archives and extracted directories (use sudo for permission issues)
sudo rm -rf /home/ubuntu/mysql
sudo rm -rf /home/ubuntu/kube-prometheus-stack
sudo rm -f /home/ubuntu/mysql-*.tgz
sudo rm -f /home/ubuntu/kube-prometheus-stack-*.tgz

# (Optional) Clean up Docker
sudo docker system prune -af
```

**Notes:**
- Ignore errors like "release not found" or "namespace not found" if resources are already gone.
- Wait a minute or two after deleting namespaces to ensure all resources are fully removed before re-running the playbook.
- Use `sudo` to remove files/directories created by Ansible with elevated privileges.

## Cleaning Up the Jenkins Slave (Maven Agent) Before Re-running the Playbook

Before re-running the Ansible playbook, clean up any previous Helm releases, Kubernetes resources, and chart files to avoid conflicts and ensure idempotency. Run these commands on the Jenkins slave (or wherever you have kubectl/helm access):

```sh
# Uninstall Helm releases (MySQL, Prometheus)
helm uninstall demo-mysql -n automationsaan
helm uninstall prometheus -n automationsaan-prom-monitoring

# Delete Kubernetes namespaces (if you want a full reset)
kubectl delete namespace automationsaan
kubectl delete namespace automationsaan-prom-monitoring

# Remove downloaded Helm chart archives and extracted directories
rm -f /home/ubuntu/mysql-*.tgz
rm -rf /home/ubuntu/mysql
rm -f /home/ubuntu/kube-prometheus-stack-*.tgz
rm -rf /home/ubuntu/kube-prometheus-stack

# (Optional) Clean up Docker
sudo docker system prune -af
```

**Note:**
- The playbook is idempotent, but Helm will not overwrite an existing release with the same name. Always clean up before re-running the playbook for a fresh install.
- If you change chart versions, update the playbook's unarchive task to match the new filename.
- For troubleshooting, see the Troubleshooting section below.

## Pre-Playbook Cleanup: Helm and Kubernetes Resources

**Before re-running the Ansible playbook that installs MySQL via Helm, ensure any previous Helm releases and related Kubernetes resources are cleaned up to avoid conflicts.**

Run these commands on the Jenkins slave (or wherever you have kubectl/Helm configured):

```sh
# List all Helm releases in all namespaces
helm list -A

# Uninstall the MySQL release (replace <namespace> and <release-name> as needed)
helm uninstall <release-name> -n <namespace>

# Example (if using 'mysql' as release name and 'default' namespace):
helm uninstall mysql -n default

# Delete any remaining MySQL pods, PVCs, or services (adjust namespace as needed)
kubectl get all -n <namespace> | grep mysql
kubectl delete pod <pod-name> -n <namespace>
kubectl delete pvc <pvc-name> -n <namespace>
kubectl delete svc <svc-name> -n <namespace>

# Optionally, delete the namespace if dedicated for MySQL (be careful!)
kubectl delete namespace <namespace>
```

**Note:** The playbook is idempotent, but Helm will not overwrite an existing release with the same name. Always clean up before re-running the playbook if you want a fresh install.

## Helm and MySQL Deployment

- The Jenkins slave Ansible playbook installs and configures **Helm** and adds both the stable and Bitnami Helm repositories.
- The playbook pulls and installs the **MySQL Helm chart from Bitnami**, ensuring a production-ready MySQL deployment on your EKS cluster.
- The MySQL deployment is idempotent: if the release does not exist, it is installed; if it exists, the playbook skips installation (see cleanup above for fresh installs).
- You can verify the deployment with:
  ```sh
  helm list -A
  kubectl get pods -A | grep mysql
  kubectl get svc -A | grep mysql
  ```
- The playbook also updates the Helm repo cache to ensure the latest charts are used.

## How to Run the Project

### 1. Clone the Repository
```
git clone <your-repo-url>
cd aws_project
```

### 2. Provision AWS Infrastructure with Terraform
- Edit `terraform/main.tf` as needed (e.g., key name, region).
- Initialize and apply Terraform:
```
pwsh
cd terraform
terraform init
terraform apply
```
- This will create the VPC, subnets, security groups, and EC2 instances for Jenkins master, build slave, and Ansible.

### 3. Configure Servers with Ansible
- Update `ansible/hosts` with the public IPs of your EC2 instances.
- Run the Ansible playbooks from the `ansible` directory:
```
cd ../ansible
ansible-playbook -i hosts jenkins-master-setup.yaml
ansible-playbook -i hosts jenkins-slave-setup.yaml
```
- This will install and configure Jenkins, Java 21, Maven, and Docker on the respective servers.
- The Jenkins slave playbook now installs Docker Buildx system-wide (in /usr/libexec/docker/cli-plugins) and enables Docker BuildKit by default, ensuring compatibility with the latest Docker build features and removing deprecation warnings. This avoids permission issues and works for all users, including Jenkins.
- The Jenkins user is added to the docker group for secure Docker access (recommended), and the old chmod 777 task is commented out for reference.

### 4. Access Jenkins
- Open a browser and go to `http://<jenkins-master-public-ip>:8080`
- Retrieve the initial admin password from the Jenkins master:
```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## kubectl and AWS CLI Installation (Jenkins Slave)

- The Ansible playbook now installs the latest stable version of `kubectl` (Kubernetes CLI) and ensures it is executable and available in the system PATH for the Jenkins slave.
- The playbook also installs or updates the AWS CLI v2 to the latest version, ensuring the Jenkins slave can interact with AWS services and EKS clusters.

## Manual AWS CLI Configuration (Jenkins Slave)

After running the playbook, log in to the Jenkins slave (or Maven build agent) to configure AWS CLI credentials for programmatic access:

1. **SSH into the Jenkins Slave:**
   ```sh
   ssh -i <your-key.pem> ubuntu@<jenkins-slave-public-ip>
   ```

2. **Configure AWS CLI with your AWS account credentials:**
   ```sh
   aws configure
   ```
   - Enter the `AWS Access Key ID` and `AWS Secret Access Key` you created earlier in the project.
   - Set the default region (e.g., `us-west-2`).
   - Set the default output format (e.g., `json`).

3. **Verify AWS CLI is working:**
   ```sh
   aws sts get-caller-identity
   ```
   - This should return your AWS account and user information.

## Download Kubernetes Credentials and Cluster Configuration

To manage your EKS cluster from the Jenkins slave, download the Kubernetes credentials and configuration file using the AWS CLI:

```sh
aws eks update-kubeconfig --region us-west-2 --name automationsaan-eks-01
```
- This command will create or update the `.kube/config` file in your home directory, allowing `kubectl` to interact with your EKS cluster.
- You can now use `kubectl` commands to manage your Kubernetes resources:
  ```sh
  kubectl get nodes
  kubectl get pods -A
  ```

## Summary of Recent Playbook Changes
- Installs and configures Java, Maven, Docker, Docker Buildx, kubectl, and AWS CLI on the Jenkins slave.
- Ensures both `jenkins` and `ubuntu` users have Docker access.
- Handles reboots if group membership changes.
- Verifies all major tools are installed and available in the system PATH.

## Jenkins Slave Docker Permissions and Robustness

- The Ansible playbook (`ansible/jenkins-slave-setup.yaml`) now ensures both the `jenkins` and `ubuntu` users are added to the `docker` group for secure Docker access. This covers the most common Jenkins agent user scenarios.
- After Docker is installed, Ansible facts are refreshed to guarantee the `docker` group exists before users are added.
- If either user's group membership changes, the playbook will automatically reboot the instance to ensure group membership is refreshed for all processes, including the Jenkins agent.
- After running the playbook and rebooting (if triggered), the Jenkins agent user (whether `jenkins` or `ubuntu`) will have full Docker and Buildx access, verified by:
  - `sudo -u ubuntu docker info` or `sudo -u jenkins docker info`
  - `sudo -u ubuntu docker buildx version` or `sudo -u jenkins docker buildx version`
  - `sudo -u ubuntu docker run --rm hello-world` or `sudo -u jenkins docker run --rm hello-world`

## Cleaning Up the Jenkins Slave (Maven Agent) Before Re-running the Playbook

Before re-running the Ansible playbook, clean up any previous Helm releases, Kubernetes resources, and chart files to avoid conflicts and ensure idempotency. Run these commands on the Jenkins slave (or wherever you have kubectl/helm access):

```sh
# Uninstall Helm releases (MySQL, Prometheus)
helm uninstall demo-mysql -n automationsaan
helm uninstall prometheus -n automationsaan-prom-monitoring

# Delete Kubernetes namespaces (if you want a full reset)
kubectl delete namespace automationsaan
kubectl delete namespace automationsaan-prom-monitoring

# Remove downloaded Helm chart archives and extracted directories
rm -f /home/ubuntu/mysql-*.tgz
rm -rf /home/ubuntu/mysql
rm -f /home/ubuntu/kube-prometheus-stack-*.tgz
rm -rf /home/ubuntu/kube-prometheus-stack

# (Optional) Clean up Docker
sudo docker system prune -af
```

**Note:**
- The playbook is idempotent, but Helm will not overwrite an existing release with the same name. Always clean up before re-running the playbook for a fresh install.
- If you change chart versions, update the playbook's unarchive task to match the new filename.
- For troubleshooting, see the Troubleshooting section below.

## Troubleshooting

- If you encounter Docker permission errors in Jenkins builds, ensure the agent user is in the `docker` group and that the instance has been rebooted after the group change.
- For Helm/MySQL issues, ensure you have cleaned up any previous Helm releases and Kubernetes resources as described in the **Pre-Playbook Cleanup** section above.
- You can manually verify with:
  - `id ubuntu` or `id jenkins` (should list `docker` in groups)
  - `sudo -u ubuntu docker info` or `sudo -u jenkins docker info` (should not show permission denied)
  - `helm list -A` and `kubectl get pods -A | grep mysql` (should show MySQL running)
- If the agent user is not in the `docker` group after running the playbook, re-run the playbook and ensure the reboot completes.

## Playbook Idempotency

- The playbook is idempotent: it only reboots if a user's group membership is newly changed, and skips unnecessary reboots otherwise.
- All major configuration steps are safe to re-run.

## Security Note

- The playbook does not use insecure permissions on the Docker socket. Docker access is managed via group membership for best security practices.

## Terraform Module Variables (sg_eks)

- The `vpc_id` variable in `terraform/sg_eks/variables.tf` specifies the VPC where the security group will be created. This allows the security group module to be reused in different VPCs by passing the appropriate VPC ID from the parent module or root configuration.
- Example usage:
  ```hcl
  module "sg_eks" {
    source = "./sg_eks"
    vpc_id = aws_vpc.automationsaan-vpc.id
  }
  ```

- The variable is defined as:
  ```hcl
  variable "vpc_id" {
    type = string
    # default = "vpc-5f680722"  # Example default, usually passed in from parent module
  }
  ```

- This ensures that the security group is always created in the correct VPC for your EKS or EC2 resources.

## Kubernetes Manifests Overview

### namespace.yaml
Defines the `automationsaan` namespace to logically isolate all project resources. Namespaces help manage environments and prevent naming conflicts in multi-tenant clusters.

### secret.yaml
Creates a Kubernetes Secret of type `kubernetes.io/dockerconfigjson` in the `automationsaan` namespace. This secret stores the base64-encoded Docker config, allowing Kubernetes to authenticate and pull images from a private registry (e.g., JFrog Artifactory). Referenced by `imagePullSecrets` in deployments.

### deployment.yaml
Defines the Deployment for the `automationsaan-rtp` application. Manages pod replicas, sets up container image pulls from JFrog, and configures ports and labels. Environment variables for external APIs have been removed for security and clarity, as only JFrog, Jenkins, AWS, SonarQube, and GitHub are used.

### service.yaml
Exposes the application to external traffic using a NodePort service. Traffic to `<node-public-ip>:30082` is forwarded to port 8000 on the service, which is routed to port 8080 in the pod (where the app listens). For production, consider using a LoadBalancer service for easier access.

### deploy.sh
A shell script to automate the deployment of all Kubernetes resources in the correct order:
1. Creates the namespace
2. Creates the Docker registry secret
3. Deploys the application
4. Exposes the application via a Service

Each manifest is commented to explain its purpose and configuration.

## Security Notes
- Sensitive values (like Docker registry credentials) are stored as Kubernetes secrets, not in plain manifests.
- For production, use Kubernetes secrets for all sensitive environment variables.

## Troubleshooting
- Ensure your application listens on the same port as specified in the service's `targetPort` (currently 8080).
- NodePort services require you to use the public IP of the node running the pod and ensure the port is open in your cloud provider's firewall/security group.
- For easier access, consider switching to a LoadBalancer service.

## Authors
- Saan Saechao AKA AutomationSaan

---
This project demonstrates a full DevOps pipeline setup using modern IaC and automation best practices on AWS.
