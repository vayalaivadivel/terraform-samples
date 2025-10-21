# --- Output the public IP and Jenkins password ---
output "jenkins_public_ip" {
  value = aws_instance.name.public_ip
}