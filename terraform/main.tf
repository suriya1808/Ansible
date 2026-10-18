# 1. Find the latest Ubuntu 24.04 image (AMI) in the region.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical, the company behind Ubuntu

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# 2. Create an SSH key so we (and Ansible) can log in to the servers.
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Upload the public half of the key to AWS.
resource "aws_key_pair" "ansible" {
  key_name   = "ansible-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

# Save the private half to a file on your computer.
resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/ansible-key.pem"
  file_permission = "0400"
}

# 3. Firewall rules: allow SSH (22) and HTTP (80) in, allow everything out.
resource "aws_security_group" "ansible" {
  name        = "ansible-sg"
  description = "Allow SSH and HTTP"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Permission for the Ansible control server (server 1) to list EC2 instances.
#    Ansible's dynamic inventory uses this to find the other servers.
resource "aws_iam_role" "control" {
  name = "ansible-control-role"

  # Allow EC2 instances to use this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Give the role read-only access to EC2 (it can look, but not change anything)
resource "aws_iam_role_policy_attachment" "control_ec2_read" {
  role       = aws_iam_role.control.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# An "instance profile" is how a role gets attached to an EC2 instance
resource "aws_iam_instance_profile" "control" {
  name = "ansible-control-profile"
  role = aws_iam_role.control.name
}

# 5. The EC2 instances. One server per entry in this list,
#    and each one gets a "Role" tag that Ansible uses to group them.
locals {
  server_roles = ["control", "python", "python", "node", "node"]
}

resource "aws_instance" "server" {
  count = length(local.server_roles)

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ansible.key_name
  vpc_security_group_ids = [aws_security_group.ansible.id]

  # Only the control server gets the EC2 read permission
  iam_instance_profile = local.server_roles[count.index] == "control" ? aws_iam_instance_profile.control.name : null

  tags = {
    Name = "ansible-server-${count.index + 1}"
    Role = local.server_roles[count.index]
  }
}
