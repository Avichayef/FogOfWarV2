#!/bin/bash

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Fog of War AWS Resources Auto-Destroy Script ===${NC}"

# Function to destroy resources
destroy_resources() {
    echo -e "${BLUE}Destroying all AWS resources...${NC}"
    terraform destroy -auto-approve
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}All AWS resources successfully destroyed.${NC}"
        echo -e "${GREEN}You will not incur any further charges.${NC}"
    else
        echo -e "${RED}Error destroying resources. Please check the logs and try again manually.${NC}"
        echo -e "${RED}Run 'terraform destroy' manually to ensure all resources are removed.${NC}"
        exit 1
    fi
}

# Check if this is being run with a timeout parameter
if [ "$1" == "--timeout" ] && [ -n "$2" ]; then
    echo -e "${BLUE}Resources will be automatically destroyed after $2 hours${NC}"
    
    # Convert hours to seconds
    TIMEOUT=$(($2 * 3600))
    
    echo -e "${BLUE}Starting countdown timer...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to cancel the auto-destroy${NC}"
    
    # Sleep for the specified time
    sleep $TIMEOUT &
    SLEEP_PID=$!
    
    # Wait for the sleep to finish or for the script to be interrupted
    wait $SLEEP_PID
    
    echo -e "${YELLOW}Time's up! Destroying resources...${NC}"
    destroy_resources
    
elif [ "$1" == "--destroy" ]; then
    # Immediate destroy
    destroy_resources
    
else
    # Show usage
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  ${YELLOW}./auto_destroy.sh --timeout HOURS${NC} - Destroy resources after HOURS"
    echo -e "  ${YELLOW}./auto_destroy.sh --destroy${NC} - Destroy resources immediately"
    echo
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  ${YELLOW}./auto_destroy.sh --timeout 8${NC} - Destroy after 8 hours"
    echo -e "  ${YELLOW}./auto_destroy.sh --destroy${NC} - Destroy now"
fi
