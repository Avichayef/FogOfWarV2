#!/bin/bash

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Fog of War App Build & Upload Script ===${NC}"

# Define paths
SERVER_DIR="$HOME/fogofwar/fog_of_war_v2/server"
APP_DIR="$HOME/fogofwar/fog_of_war_v2/fog_of_war_app"
APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-debug.apk"
GDRIVE_FOLDER="avichayef_g_drive:FogOfWar"

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Step 1: Check if server is running, start if not
echo -e "${YELLOW}Step 1: Checking server status...${NC}"
if pgrep -f "node server.js" > /dev/null; then
    echo -e "${GREEN}Server is already running.${NC}"
else
    echo -e "${YELLOW}Starting server...${NC}"
    cd "$SERVER_DIR"
    
    # Use Node.js v16
    nvm use 16 > /dev/null
    
    # Start the server in background
    node server.js > server.log 2>&1 &
    
    # Wait a moment for server to start
    sleep 2
    
    # Check if server started successfully
    if pgrep -f "node server.js" > /dev/null; then
        echo -e "${GREEN}Server started successfully.${NC}"
    else
        echo -e "${RED}Failed to start server. Check server.log for details.${NC}"
        exit 1
    fi
fi

# Step 2: Build the APK
echo -e "${YELLOW}Step 2: Building APK...${NC}"
cd "$APP_DIR"
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
rclone mkdir "$GDRIVE_FOLDER" 2>/dev/null

# Upload the APK
echo -e "${YELLOW}Uploading app-debug.apk to $GDRIVE_FOLDER...${NC}"
rclone copy "$APK_PATH" "$GDRIVE_FOLDER"

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
