# Variables used for EKS module configuration

# Security group IDs to associate with EKS node group (passed from VPC or SG module)
variable "sg_ids" {
  type = string
}

# List of subnet IDs for EKS cluster and node group networking
variable "subnet_ids" {
  type = list
}

# VPC ID where EKS resources will be created
variable "vpc_id" {
  # default = "vpc-5f680722" # Example default, usually passed in from parent module
  type = string
}
