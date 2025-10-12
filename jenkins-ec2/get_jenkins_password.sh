#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# Extract the EC2 instance IP from the command-line arguments.
INSTANCE_IP=$1

# Get the path to the SSH private key from Terraform variables.
# This assumes you have already created a `terraform.tfvars` file.
SSH_KEY_PATH=$(cat terraform.tfvars | grep "ssh_key_path" | cut -d'=' -f2 | tr -d '" ' | tr -d "'")

# Use SSH to connect to the EC2 instance and retrieve the Jenkins password.
# The 'until' loop waits until the password file exists on the server.
JENKINS_PASSWORD=$(ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "ec2-user@$INSTANCE_IP" "until sudo cat /var/lib/jenkins/secrets/initialAdminPassword; do sleep 5; done")

# Output the result as a JSON object, which the external data source will read.
# The `jq` tool is used for JSON formatting.
jq -n --arg password "$JENKINS_PASSWORD" '{"jenkins_admin_password":$password}'