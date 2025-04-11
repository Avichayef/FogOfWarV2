resource "aws_security_group" "server_sg" {
  name        = "${var.environment}-fog-of-war-sg"
  description = "Security group for Fog of War server"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP access for the API
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "API access"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.environment}-fog-of-war-sg"
    Environment = var.environment
  }
}

# Create an IAM role for the EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-fog-of-war-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name        = "${var.environment}-fog-of-war-ec2-role"
    Environment = var.environment
  }
}

# Create an instance profile for the EC2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-fog-of-war-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
