output "public_ips" {
  description = "Public IP addresses of the servers"
  value       = aws_instance.server[*].public_ip
}

output "ssh_command_example" {
  description = "How to SSH into the first server"
  value       = "ssh -i terraform/ansible-key.pem ubuntu@${aws_instance.server[0].public_ip}"
}
