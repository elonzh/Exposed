#!/bin/bash
set -e

echo "=== Setting up Exposed Doc ZH Sync ==="

# Install opencode CLI
npm install -g opencode-ai

# Check Docker
if [ -S /var/run/docker.sock ]; then
    echo "Docker socket: OK"
else
    echo "WARNING: Docker socket not found. Docker build will not work."
fi

# Check Docker command
if command -v docker &> /dev/null; then
    echo "Docker command: OK"
else
    echo "WARNING: Docker command not found. Please ensure Docker CLI is installed."
fi

# Make scripts executable
chmod +x documentation-website-zh/scripts/*.sh 2>/dev/null || true
