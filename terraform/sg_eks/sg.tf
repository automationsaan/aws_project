# Security group for EKS worker nodes
# Allows SSH access from anywhere (port 22) and all outbound traffic
resource "aws_security_group" "worker_node_sg" {
  name        = "eks-test"
  description = "Allow ssh inbound traffic"
  vpc_id      = var.vpc_id

  # Inbound rule: allow SSH from any IP (for management/debugging)
  ingress {
    description      = "ssh access to public"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  # Outbound rule: allow all traffic to any destination
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}