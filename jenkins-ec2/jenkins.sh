#!/bin/bash
set -e

# Update system
sudo dnf update -y

# Install Amazon Corretto 21 (Java 21)
sudo dnf install -y java-21-amazon-corretto

# Add Jenkins repo
sudo curl -fsSL https://pkg.jenkins.io/redhat-stable/jenkins.repo -o /etc/yum.repos.d/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install dependencies
sudo dnf install -y fontconfig git

# Install Jenkins (latest stable)
sudo dnf install -y jenkins

# Enable Jenkins service
sudo systemctl enable jenkins

# Start Jenkins service
sudo systemctl start jenkins