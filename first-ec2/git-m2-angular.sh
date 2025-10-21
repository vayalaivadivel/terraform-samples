#!/bin/bash
# Update the system
sudo yum update -y
# Install Git using the yum package manager
sudo yum install git -y

sudo yum update -y
              
# Install Java 8 using the OpenJDK package for Amazon Linux
sudo yum install java-1.8.0-openjdk-devel -y
# Add EPEL repository for older Maven versions, and then install Maven
sudo yum install -y epel-release
sudo yum install -y maven
              
# Set JAVA_HOME and M2_HOME environment variables
# This section ensures that the variables are set correctly for new shell sessions
echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))" | sudo tee -a /etc/profile.d/java.sh
echo "export M2_HOME=/usr/share/maven" | sudo tee -a /etc/profile.d/maven.sh
echo "export PATH=$JAVA_HOME/bin:$M2_HOME/bin:$PATH" | sudo tee -a /etc/profile.d/maven.sh
              
# Source the profile to apply changes to the current script environment
source /etc/profile.d/java.sh
source /etc/profile.d/maven.sh