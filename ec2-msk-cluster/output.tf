############################
# Outputs
############################
output "msk_cluster_arn" {
  value = aws_msk_cluster.kafka.arn
}
output "ec2_public_ip" {
  value       = aws_instance.ec2.public_ip
  description = "Public IP of EC2 instance"
}

output "kafka_bootstrap_brokers_tls" {
  value       = aws_msk_cluster.kafka.bootstrap_brokers_tls
  description = "Kafka bootstrap brokers (TLS)"
}