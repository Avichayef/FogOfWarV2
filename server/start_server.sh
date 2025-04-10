#!/bin/bash

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Use Node.js v16
nvm use 16

# Start the server
node server.js > server.log 2>&1 &

echo "Server started in background. Check server.log for output."
echo "To stop the server, run: pkill -f 'node server.js'"
