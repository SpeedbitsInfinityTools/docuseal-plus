#!/bin/bash
# =============================================================================
# Login to GitHub Container Registry (GHCR)
# =============================================================================
# Run this before pushing images to GHCR
# Credentials are loaded from keys.yml
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS_FILE="$SCRIPT_DIR/keys.yml"

# Parse YAML (simple grep-based parsing)
parse_yaml() {
    local key=$1
    grep "^${key}:" "$KEYS_FILE" 2>/dev/null | sed "s/^${key}:[[:space:]]*//" | tr -d '"' | tr -d "'"
}

echo "========================================================"
echo "Login to GitHub Container Registry"
echo "========================================================"
echo ""

# Check if keys.yml exists
if [ ! -f "$KEYS_FILE" ]; then
    echo "Error: keys.yml not found!"
    echo ""
    echo "Please create $KEYS_FILE with your GHCR credentials."
    echo "Copy from keys.template.yml and fill in your values:"
    echo ""
    echo "  cp $SCRIPT_DIR/keys.template.yml $KEYS_FILE"
    echo "  nano $KEYS_FILE"
    echo ""
    exit 1
fi

# Load credentials
GITHUB_USERNAME=$(parse_yaml "github_username")
GITHUB_PAT=$(parse_yaml "github_pat")
REGISTRY=$(parse_yaml "registry")

# Validate credentials
if [ -z "$GITHUB_USERNAME" ] || [ "$GITHUB_USERNAME" = "your-github-username" ]; then
    echo "Error: Invalid github_username in keys.yml"
    exit 1
fi

if [ -z "$GITHUB_PAT" ] || [[ "$GITHUB_PAT" == ghp_x* ]]; then
    echo "Error: Invalid github_pat in keys.yml (still contains placeholder)"
    exit 1
fi

REGISTRY="${REGISTRY:-ghcr.io}"

# Check if already logged in
if docker login "$REGISTRY" --get-login > /dev/null 2>&1; then
    CURRENT_USER=$(docker login "$REGISTRY" --get-login 2>/dev/null || echo "unknown")
    echo "Already logged in as: $CURRENT_USER"
    read -p "Do you want to re-login? (y/N): " RELOGIN
    if [[ ! "$RELOGIN" =~ ^[Yy]$ ]]; then
        echo "Using existing login"
        exit 0
    fi
fi

# Login
echo "Logging in to $REGISTRY as $GITHUB_USERNAME..."
echo "$GITHUB_PAT" | docker login "$REGISTRY" -u "$GITHUB_USERNAME" --password-stdin

echo ""
echo "[OK] Successfully logged in to $REGISTRY"
echo ""
echo "You can now run ./build-and-push.sh to build and push images."
echo ""
