#!/bin/bash

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Update App API Endpoint Script ===${NC}"

# Get the server IP from Terraform output
if [ ! -f "terraform.tfstate" ]; then
    echo -e "${RED}Error: terraform.tfstate not found!${NC}"
    echo -e "${BLUE}Please run the deployment script first:${NC}"
    echo -e "${YELLOW}./deploy.sh${NC}"
    exit 1
fi

# Get the server IP
SERVER_IP=$(terraform output -raw server_public_ip)

if [ -z "$SERVER_IP" ]; then
    echo -e "${RED}Error: Could not get server IP from Terraform output!${NC}"
    exit 1
fi

# Path to the API service file
API_FILE="../../../fog_of_war_app/lib/services/api_service.dart"

if [ ! -f "$API_FILE" ]; then
    echo -e "${RED}Error: API service file not found at $API_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}Updating API endpoint to point to: $SERVER_IP${NC}"

# Update the API endpoint
sed -i "s|baseUrl = 'http://[^']*'|baseUrl = 'http://$SERVER_IP:3000/api'|g" "$API_FILE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}API endpoint updated successfully!${NC}"
    echo -e "${BLUE}New endpoint: http://$SERVER_IP:3000/api${NC}"
    
    echo -e "${YELLOW}Now build and upload the app:${NC}"
    echo -e "${YELLOW}cd ~/fogofwar/fog_of_war_v2${NC}"
    echo -e "${YELLOW}./build_and_upload.sh${NC}"
else
    echo -e "${RED}Failed to update API endpoint!${NC}"
    echo -e "${BLUE}Please manually update the API endpoint in:${NC}"
    echo -e "${YELLOW}$API_FILE${NC}"
    echo -e "${BLUE}Change baseUrl to: 'http://$SERVER_IP:3000/api'${NC}"
    exit 1
fi
