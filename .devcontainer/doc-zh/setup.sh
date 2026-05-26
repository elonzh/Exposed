#!/bin/bash
set -e

echo "=== Setting up Exposed Doc ZH Sync ==="

# Install opencode CLI
if ! command -v opencode &> /dev/null; then
    echo "Installing opencode..."
    curl -fsSL https://opencode.ai/install | bash
    export PATH="$HOME/.local/bin:$PATH"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
else
    echo "opencode already installed."
fi

# Check Docker
if [ -S /var/run/docker.sock ]; then
    echo "Docker socket: OK"
else
    echo "WARNING: Docker socket not found. build.sh will not work."
fi

# Make scripts executable
chmod +x documentation-website-zh/scripts/*.sh 2>/dev/null || true
