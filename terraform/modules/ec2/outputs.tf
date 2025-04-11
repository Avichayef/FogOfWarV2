output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.fog_of_war_server.id
}

output "private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.fog_of_war_server.private_ip
}

output "public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = aws_instance.fog_of_war_server.public_dns
}
