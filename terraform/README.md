# Fog of War App - AWS Terraform Deployment

This directory contains Terraform configurations to deploy the Fog of War app to AWS.

## Architecture

The deployment consists of:

- VPC with public subnet
- EC2 instance (t2.micro - free tier eligible)
- Security group allowing SSH and API access
- Elastic IP for a static public IP address
- IAM role and instance profile for EC2

## Prerequisites

1. [Terraform](https://www.terraform.io/downloads.html) installed (v1.0.0+)
2. AWS account with appropriate permissions
3. AWS CLI installed and configured with your credentials
4. SSH key pair created in AWS

## Deployment Instructions

### 1. Initialize Terraform

```bash
cd terraform/environments/dev
terraform init
```

### 2. Configure Variables

Create a `terraform.tfvars` file based on the example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to set your AWS key pair name and any other customizations.

### 3. Deploy with Automatic Cleanup

We've created scripts to simplify deployment and ensure resources are cleaned up to avoid charges:

```bash
# Deploy and automatically destroy after 8 hours
./deploy.sh --timeout 8

# Deploy with automatic cleanup on failure
./deploy.sh --auto-destroy

# Deploy without automatic cleanup
./deploy.sh
```

The deployment script will:
1. Initialize Terraform
2. Plan and apply the configuration
3. Output the server details
4. Set up automatic destruction if requested

### 5. Access the Server

After deployment completes, Terraform will output:
- The server's public IP address
- The API endpoint URL

You can SSH into the server using:

```bash
ssh -i /path/to/your-key.pem ec2-user@[SERVER_PUBLIC_IP]
```

### 6. Update the App Configuration

Update your Flutter app's API service to point to the new server:

```dart
// lib/services/api_service.dart
final String baseUrl = 'http://[SERVER_PUBLIC_IP]:3000/api';
```

## Cleanup

To destroy all resources when you're done testing, use the auto_destroy script:

```bash
# Destroy immediately
./auto_destroy.sh --destroy

# Set up timed destruction (e.g., after 4 hours)
./auto_destroy.sh --timeout 4
```

This ensures you won't incur unexpected AWS charges.

## Cost Estimation

The resources deployed are eligible for the AWS Free Tier for 12 months, which includes:
- 750 hours per month of t2.micro EC2 instance usage
- 30 GB of EBS storage
- 15 GB of outbound data transfer

After the free tier expires, the estimated cost is approximately $8-10 per month.
