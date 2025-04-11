output "server_public_ip" {
  description = "The public IP address of the server"
  value       = module.networking.elastic_ip
}

output "server_public_dns" {
  description = "The public DNS name of the server"
  value       = module.ec2.public_dns
}

output "api_endpoint" {
  description = "The API endpoint URL"
  value       = "http://${module.networking.elastic_ip}:3000/api"
}
