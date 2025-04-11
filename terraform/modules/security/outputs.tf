output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.server_sg.id
}

output "instance_profile_name" {
  description = "The name of the instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "instance_profile_arn" {
  description = "The ARN of the instance profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}
