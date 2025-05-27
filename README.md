# AWS DevOps Project

This project provisions a complete DevOps environment on AWS using Infrastructure as Code and automation tools. It includes:
- A custom VPC with public subnets
- EC2 instances for Jenkins master, Jenkins build slave, and an Ansible server
- Security groups for secure access
- Automated setup of Jenkins, Java, Maven, and Docker using Ansible

## Tools and Technologies Used
- **Terraform**: Infrastructure as Code for AWS resources (VPC, subnets, EC2, security groups, etc.)
- **Ansible**: Configuration management and automation for provisioning Jenkins, Java, Maven, and Docker
- **Jenkins**: Continuous Integration/Continuous Deployment (CI/CD) server
- **Maven**: Build automation tool for Java projects
- **Docker**: Containerization platform
- **AWS EC2**: Virtual machines for running Jenkins and Ansible
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
