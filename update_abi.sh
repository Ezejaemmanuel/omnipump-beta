#!/bin/bash

# Define the paths
SOURCE_DIR=~/blockchain-development/projects_with_oz/hardhat-foundry-pump-fun-like
ABI_FILE=/home/jatique/blockchain-development/projects_with_oz/hardhat-foundry-pump-fun-like/out/mainEngine.sol/MainEngine.abi.json
DESTINATION_PATHS=(
    "/home/jatique/blockchain-development/projects_with_oz/pump-graph/ethereum-blocks/abis/mainEngine.json"
    # Add more paths here if needed
)

# Change to the source directory
cd "$SOURCE_DIR" || exit 1

# Run forge build command
forge build --extra-output-files abi

# Wait for 3 seconds
sleep 3

# Check if the ABI file exists
if [ ! -f "$ABI_FILE" ]; then
    echo "Error: ABI file not found at $ABI_FILE"
    exit 1
fi

# Copy the contents of the ABI file to all destination paths
for dest in "${DESTINATION_PATHS[@]}"; do
    cp "$ABI_FILE" "$dest"
    if [ $? -eq 0 ]; then
        echo "Successfully copied ABI to $dest"
    else
        echo "Error: Failed to copy ABI to $dest"
    fi
done

echo "Script execution completed."