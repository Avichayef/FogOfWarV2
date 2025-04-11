resource "aws_instance" "fog_of_war_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.instance_profile_name

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    # Update system packages
    yum update -y
    
    # Install Node.js
    curl -sL https://rpm.nodesource.com/setup_16.x | bash -
    yum install -y nodejs
    
    # Install Git
    yum install -y git
    
    # Install PM2 for process management
    npm install -g pm2
    
    # Create app directory
    mkdir -p /home/ec2-user/fogofwar
    
    # Clone the repository
    git clone https://github.com/Avichayef/FogOfWarV2.git /home/ec2-user/fogofwar
    
    # Set permissions
    chown -R ec2-user:ec2-user /home/ec2-user/fogofwar
    
    # Install dependencies and start the server
    cd /home/ec2-user/fogofwar/server
    npm install
    
    # Start the server with PM2
    pm2 start server.js --name fog-of-war-server
    
    # Save PM2 configuration to restart on reboot
    pm2 save
    pm2 startup
    
    # Configure PM2 to start on boot
    env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ec2-user --hp /home/ec2-user
  EOF

  tags = {
    Name        = "${var.environment}-fog-of-war-server"
    Environment = var.environment
  }
}

# Associate the Elastic IP with the EC2 instance
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.fog_of_war_server.id
  allocation_id = var.elastic_ip_id
}
