#!/bin/bash
set -e

echo "🚀 Setting up Git, Node.js (npm 8.3.0), Java 8 (Corretto), and Maven on Amazon Linux..."

# Detect OS version
OS_VERSION=$(cat /etc/system-release)
echo "Detected OS: $OS_VERSION"

# Update system
sudo yum update -y || sudo dnf update -y

# --- Install Git ---
echo "📦 Installing Git..."
sudo yum install -y git || sudo dnf install -y git
git --version

# --- Install Node.js 16 + npm 8.3.0 ---
echo "🧩 Installing Node.js 16 (includes npm 8.3.0)..."
sudo yum remove -y nodejs npm || sudo dnf remove -y nodejs npm || true
curl -fsSL https://rpm.nodesource.com/setup_16.x | sudo bash -
sudo yum install -y nodejs || sudo dnf install -y nodejs
sudo npm install -g npm@8.3.0
node -v
npm -v

# # --- Install Java 21 (Amazon Corretto) ---

sudo yum install java-21-amazon-corretto-devel -y

# Download and extract Maven
sudo wget https://dlcdn.apache.org/maven/maven-3/3.9.11/binaries/apache-maven-3.9.11-bin.tar.gz
sudo tar -xvzf apache-maven-3.9.11-bin.tar.gz -C /opt
sudo ln -s /opt/apache-maven-3.9.11 /opt/maven

# Set up environment variables
echo "export M2_HOME=/opt/maven" >> /etc/profile.d/maven.sh
echo "export PATH=${M2_HOME}/bin:${PATH}" >> /etc/profile.d/maven.sh
chmod +x /etc/profile.d/maven.sh

# Reload profile to apply changes
source /etc/profile.d/maven.sh