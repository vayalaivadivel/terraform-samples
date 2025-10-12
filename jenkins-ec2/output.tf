# --- Output the public IP and Jenkins password ---
output "jenkins_public_ip" {
  value = aws_instance.name.public_ip
}

output "jenkins_admin_password" {
  value     = data.external.jenkins_password.result.jenkins_admin_password
  #sensitive = true # Mark as sensitive to hide from CLI output
}