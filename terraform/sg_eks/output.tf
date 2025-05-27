# Output the ID of the public security group for worker nodes
# This is used by other modules (e.g., EKS) to associate the correct security group with resources
output "security_group_public" {
   value = "${aws_security_group.worker_node_sg.id}"
}