#!/bin/bash
# =============================================================================
# Docker Buildx Setup Script for DocuSeal Plus
# =============================================================================
# Run this once to set up multi-architecture Docker builds on your ARM laptop
# =============================================================================

set -e

echo "========================================================"
echo "Docker Buildx Setup for Multi-Architecture Builds"
echo "========================================================"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

echo "[OK] Docker is running"

# Install QEMU for cross-platform builds
echo ""
echo "Installing QEMU for cross-platform emulation..."
docker run --privileged --rm tonistiigi/binfmt --install all

# Check if multiarch builder exists
if docker buildx inspect multiarch > /dev/null 2>&1; then
    echo ""
    echo "Builder 'multiarch' already exists, using it..."
    docker buildx use multiarch
else
    echo ""
    echo "Creating new buildx builder 'multiarch'..."
    docker buildx create --name multiarch --use
fi

# Bootstrap the builder
echo ""
echo "Bootstrapping builder..."
docker buildx inspect --bootstrap

echo ""
echo "========================================================"
echo "Setup complete!"
echo "========================================================"
echo ""
echo "Available platforms:"
docker buildx inspect | grep -i platforms
echo ""
echo "Next steps:"
echo "  1. Copy keys.template.yml to keys.yml and add your credentials"
echo "  2. Run ./login-ghcr.sh to login to GitHub Container Registry"
echo "  3. Run ./build-test.sh to test building locally"
echo "  4. Run ./build-and-push.sh to build and push to GHCR"
echo ""
