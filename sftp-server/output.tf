###############################################################
# OUTPUTS
###############################################################
output "sftp_server_id" {
  value = aws_transfer_server.sftp_server.id
}

output "sftp_server_endpoint" {
  value = aws_transfer_server.sftp_server.endpoint
}

output "sftp_username" {
  value = aws_transfer_user.sftp_user.user_name
}
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}
output "sftp_private_key_path" {
  value = local_file.sftp_private_key.filename
}