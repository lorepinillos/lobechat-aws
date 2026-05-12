output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.main.id
}

output "public_ip" {
  description = "Elastic IP attached to the instance."
  value       = aws_eip.instance.public_ip
}

output "public_hostname" {
  description = "traefik.me hostname that resolves to the EIP (has a valid public TLS cert)."
  value       = local.public_hostname
}

output "https_url" {
  description = "The HTTPS URL the grader will hit."
  value       = "https://${local.public_hostname}"
}

output "ssh_command" {
  description = "SSH into the instance."
  value       = "ssh -i ~/.ssh/id_ed25519 ubuntu@${aws_eip.instance.public_ip}"
}

