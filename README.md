# AWS DevOps Project

This project provisions a complete DevOps and Kubernetes environment on AWS using Infrastructure as Code and automation tools. It includes:
- A custom VPC with public subnets
- EC2 instances for Jenkins master, Jenkins build slave, and an Ansible server
- Security groups for secure access
- Automated setup of Jenkins, Java, Maven, Docker, kubectl, and AWS CLI using Ansible
- An Amazon EKS (Elastic Kubernetes Service) cluster with autoscaling node groups
- Kubernetes cluster management and integration with Jenkins CI/CD pipelines

## Tools and Technologies Used
- **Terraform**: Infrastructure as Code for AWS resources (VPC, subnets, EC2, security groups, EKS clusters, node groups, etc.)
- **Ansible**: Configuration management and automation for provisioning Jenkins, Java, Maven, Docker, kubectl, and AWS CLI
- **Jenkins**: Continuous Integration/Continuous Deployment (CI/CD) server
- **Maven**: Build automation tool for Java projects
- **Docker**: Containerization platform
- **Kubernetes**: Container orchestration platform for deploying and managing applications
- **Amazon EKS**: Managed Kubernetes service on AWS, including cluster and autoscaling node group provisioning
- **AWS CLI**: Command-line interface for managing AWS resources and EKS clusters
- **kubectl**: Kubernetes CLI for managing clusters and workloads
- **AWS EC2**: Virtual machines for running Jenkins, Ansible, and other workloads
- **Ubuntu 22.04+**: Operating system for all instances

## Project Structure
```
aws_project/
├── ansible/
│   ├── hosts
│   ├── jenkins-master-setup.yaml
│   └── jenkins-slave-setup.yaml
├── terraform/
│   └── main.tf
└── .gitignore
```

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

## Troubleshooting

- If you encounter Docker permission errors in Jenkins builds, ensure the agent user is in the `docker` group and that the instance has been rebooted after the group change.
- You can manually verify with:
  - `id ubuntu` or `id jenkins` (should list `docker` in groups)
  - `sudo -u ubuntu docker info` or `sudo -u jenkins docker info` (should not show permission denied)
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

## Notes
- All infrastructure is created in the AWS region specified in `main.tf` (default: `us-west-2`).
- Terraform state files are excluded from version control via `.gitignore`.
- Security groups allow SSH (22) and Jenkins (8080) access from anywhere. Adjust as needed for production.

## Authors
- Saan Saechao AKA AutomationSaan

---
This project demonstrates a full DevOps pipeline setup using modern IaC and automation best practices on AWS.
