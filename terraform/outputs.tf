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
  description = "The HTTPS URL the grader will hit (LobeChat)."
  value       = "https://${local.public_hostname}"
}

output "auth_url" {
  description = "Casdoor SSO URL."
  value       = "https://${local.auth_hostname}"
}

output "s3_url" {
  description = "MinIO S3 API URL (presigned URLs sign against this host)."
  value       = "https://${local.s3_hostname}"
}

output "ssh_command" {
  description = "SSH into the instance."
  value       = "ssh -i ~/.ssh/id_ed25519 ubuntu@${aws_eip.instance.public_ip}"
}

