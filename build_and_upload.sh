#!/bin/bash

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show progress spinner
spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

echo -e "${YELLOW}=== Fog of War App Build & Upload Script ===${NC}"

# Define paths
SERVER_DIR="$HOME/fogofwar/fog_of_war_v2/server"
APP_DIR="$HOME/fogofwar/fog_of_war_v2/fog_of_war_app"
APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-debug.apk"
GDRIVE_FOLDER="avichayef_g_drive:FogOfWar"

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Step 1: Check if server is running, restart if needed
echo -e "${YELLOW}Step 1: Checking server status...${NC}"

# Check if server is running
if pgrep -f "node server.js" > /dev/null; then
    echo -e "${BLUE}Server is running. Stopping it for a clean restart...${NC}"
    pkill -f "node server.js"

    # Wait for server to stop
    echo -ne "${BLUE}Waiting for server to stop${NC}"
    while pgrep -f "node server.js" > /dev/null; do
        echo -n "."
        sleep 0.5
    done
    echo -e "\n${GREEN}Server stopped successfully.${NC}"
fi

# Start the server
echo -e "${YELLOW}Starting server...${NC}"
cd "$SERVER_DIR"

# Use Node.js v16
nvm use 16 > /dev/null

# Start the server in background
node server.js > server.log 2>&1 &
SERVER_PID=$!

# Show spinner while waiting for server to initialize
echo -ne "${BLUE}Initializing server${NC}"
sleep 1
for i in {1..5}; do
    echo -n "."
    sleep 0.5
done
echo ""

# Check if server started successfully
if pgrep -f "node server.js" > /dev/null; then
    echo -e "${GREEN}Server started successfully (PID: $SERVER_PID).${NC}"
else
    echo -e "${RED}Failed to start server. Check server.log for details.${NC}"
    exit 1
fi

# Step 2: Build the APK
echo -e "${YELLOW}Step 2: Building APK...${NC}"
cd "$APP_DIR"

# Show progress message
echo -e "${BLUE}Running Flutter build command...${NC}"
echo -e "${BLUE}This may take a few minutes. Please wait...${NC}"

# Build the APK with a progress indicator
flutter build apk --debug

# Check if build was successful
if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}APK build failed. APK file not found.${NC}"
    exit 1
fi

echo -e "${GREEN}APK built successfully at: $APK_PATH${NC}"

# Step 3: Upload to Google Drive
echo -e "${YELLOW}Step 3: Uploading to Google Drive...${NC}"

# Create folder if it doesn't exist
echo -e "${BLUE}Checking Google Drive folder...${NC}"
rclone mkdir "$GDRIVE_FOLDER" 2>/dev/null

# Upload the APK with progress indicator
echo -e "${BLUE}Uploading app-debug.apk to $GDRIVE_FOLDER...${NC}"
echo -ne "${BLUE}Upload in progress${NC}"

# Start upload in background and show progress
rclone copy "$APK_PATH" "$GDRIVE_FOLDER" &
UPLOAD_PID=$!

# Show progress dots
while kill -0 $UPLOAD_PID 2>/dev/null; do
    echo -n "."
    sleep 0.5
done
echo ""

# Verify upload
if rclone ls "$GDRIVE_FOLDER" | grep -q "app-debug.apk"; then
    echo -e "${GREEN}Upload successful!${NC}"
    echo -e "${GREEN}APK is available at: $GDRIVE_FOLDER/app-debug.apk${NC}"
else
    echo -e "${RED}Upload verification failed. Please check rclone configuration.${NC}"
    exit 1
fi

echo -e "${GREEN}=== All tasks completed successfully! ===${NC}"
echo -e "${YELLOW}Server is running in background.${NC}"
echo -e "${YELLOW}To stop the server: pkill -f 'node server.js'${NC}"
echo -e "${YELLOW}APK is available in your Google Drive in the FogOfWar folder.${NC}"
