# The file path to your private key for SSH access.
# This is explicitly for the external script to find the key.
variable "ssh_key_path" {
  description = "The path to the private key file for SSH."
  type        = string
  default = "common-key.pem"
}