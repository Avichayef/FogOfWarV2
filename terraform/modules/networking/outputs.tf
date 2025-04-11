output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.fog_of_war_vpc.id
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public_subnet.id
}

output "elastic_ip" {
  description = "The Elastic IP for the server"
  value       = aws_eip.server_eip.public_ip
}

output "elastic_ip_id" {
  description = "The allocation ID of the Elastic IP"
  value       = aws_eip.server_eip.id
}
