#!/bin/bash

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Fog of War AWS Deployment Script ===${NC}"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${RED}Error: terraform.tfvars file not found!${NC}"
    echo -e "${BLUE}Please create terraform.tfvars based on the example:${NC}"
    echo -e "${YELLOW}cp terraform.tfvars.example terraform.tfvars${NC}"
    echo -e "${BLUE}Then edit the file to set your AWS key pair name and other settings.${NC}"
    exit 1
fi

# Function to handle errors and cleanup
cleanup_on_error() {
    echo -e "${RED}Deployment failed!${NC}"
    
    if [ "$1" == "--auto-destroy" ]; then
        echo -e "${YELLOW}Automatically destroying all resources due to deployment failure...${NC}"
        terraform destroy -auto-approve
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}All AWS resources successfully destroyed.${NC}"
        else
            echo -e "${RED}Error destroying resources. Please run 'terraform destroy' manually.${NC}"
        fi
    else
        echo -e "${YELLOW}Resources have been partially created.${NC}"
        echo -e "${YELLOW}Run './auto_destroy.sh --destroy' to clean up all resources.${NC}"
    fi
    
    exit 1
}

# Parse command line arguments
AUTO_DESTROY=false
TIMEOUT=0

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --auto-destroy) AUTO_DESTROY=true ;;
        --timeout) TIMEOUT="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Initialize Terraform
echo -e "${BLUE}Initializing Terraform...${NC}"
terraform init

if [ $? -ne 0 ]; then
    echo -e "${RED}Terraform initialization failed!${NC}"
    exit 1
fi

# Plan the deployment
echo -e "${BLUE}Planning deployment...${NC}"
terraform plan -out=tfplan

if [ $? -ne 0 ]; then
    echo -e "${RED}Terraform plan failed!${NC}"
    exit 1
fi

# Apply the configuration
echo -e "${BLUE}Deploying infrastructure...${NC}"
terraform apply tfplan

# Check if deployment was successful
if [ $? -ne 0 ]; then
    cleanup_on_error $([[ "$AUTO_DESTROY" == true ]] && echo "--auto-destroy")
fi

# Get outputs
echo -e "${GREEN}Deployment successful!${NC}"
echo -e "${BLUE}Server details:${NC}"
terraform output

# Update the app configuration
SERVER_IP=$(terraform output -raw server_public_ip)
API_ENDPOINT=$(terraform output -raw api_endpoint)

echo -e "${YELLOW}=== Next Steps ===${NC}"
echo -e "${BLUE}1. Update your app's API endpoint:${NC}"
echo -e "   ${YELLOW}Edit fog_of_war_app/lib/services/api_service.dart${NC}"
echo -e "   ${YELLOW}Change baseUrl to: 'http://$SERVER_IP:3000/api'${NC}"
echo -e "${BLUE}2. Build and deploy your app:${NC}"
echo -e "   ${YELLOW}cd ~/fogofwar/fog_of_war_v2${NC}"
echo -e "   ${YELLOW}./build_and_upload.sh${NC}"

# Set up auto-destroy if timeout is specified
if [ "$TIMEOUT" -gt 0 ]; then
    echo -e "${BLUE}Setting up auto-destroy after $TIMEOUT hours...${NC}"
    echo -e "${YELLOW}Resources will be automatically destroyed after $TIMEOUT hours.${NC}"
    
    # Start the auto-destroy script in the background
    ./auto_destroy.sh --timeout $TIMEOUT &
    
    echo -e "${BLUE}Auto-destroy process started (PID: $!)${NC}"
    echo -e "${BLUE}You can cancel it by running: kill $!${NC}"
fi

echo -e "${YELLOW}=== Important ===${NC}"
echo -e "${BLUE}To avoid AWS charges, destroy resources when done:${NC}"
echo -e "${YELLOW}./auto_destroy.sh --destroy${NC}"
