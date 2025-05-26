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

### 4. Access Jenkins
- Open a browser and go to `http://<jenkins-master-public-ip>:8080`
- Retrieve the initial admin password from the Jenkins master:
```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## Notes
- All infrastructure is created in the AWS region specified in `main.tf` (default: `us-west-2`).
- Terraform state files are excluded from version control via `.gitignore`.
- Security groups allow SSH (22) and Jenkins (8080) access from anywhere. Adjust as needed for production.

## Authors
- Saan Saechao AKA AutomationSaan

---
This project demonstrates a full DevOps pipeline setup using modern IaC and automation best practices on AWS.
