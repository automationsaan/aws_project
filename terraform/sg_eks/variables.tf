# Variable for the VPC ID where the security group will be created
# This allows the security group module to be reused in different VPCs
variable "vpc_id" {
   //default = "vpc-5f680722"  # Example default, usually passed in from parent module
   type = string
}