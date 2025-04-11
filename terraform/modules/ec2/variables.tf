variable "environment" {
  description = "The environment (dev, prod, etc.)"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
  default     = "ami-0c7217cdde317cfec" # Amazon Linux 2 AMI in us-east-1
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
  default     = "t2.micro" # Free tier eligible
}

variable "key_name" {
  description = "The key name to use for the instance"
  type        = string
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch in"
  type        = string
}

variable "security_group_id" {
  description = "The VPC Security Group ID to associate with"
  type        = string
}

variable "instance_profile_name" {
  description = "The name of the instance profile to use"
  type        = string
}

variable "elastic_ip_id" {
  description = "The allocation ID of the Elastic IP to associate with the instance"
  type        = string
}
