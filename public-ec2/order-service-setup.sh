#!/bin/bash
set -e

# Log user-data output (very helpful for debugging)
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "Updating system..."
yum update -y

echo "Installing Java 21 (Amazon Corretto)..."
cd /tmp
wget -q https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.rpm
yum localinstall -y amazon-corretto-21-x64-linux-jdk.rpm

echo "Verifying Java installation..."
java -version
javac -version

echo "Java 21 installation completed successfully."