#!/bin/bash
# =============================================================================
# Reset Docker Buildx Builder
# =============================================================================
# Run this if you get EOF errors during builds
# =============================================================================

set -e

echo "========================================================"
echo "Resetting Docker Buildx Builder"
echo "========================================================"
echo ""

# Stop and remove the current builder
echo "Removing existing 'multiarch' builder..."
docker buildx rm multiarch 2>/dev/null || true

# Also clean up any dangling buildx containers
echo "Cleaning up buildx containers..."
docker ps -a --filter "name=buildx" -q | xargs -r docker rm -f 2>/dev/null || true

# Reinstall QEMU (sometimes it gets into a bad state)
echo ""
echo "Reinstalling QEMU..."
docker run --privileged --rm tonistiigi/binfmt --install all

# Create fresh builder
echo ""
echo "Creating fresh 'multiarch' builder..."
docker buildx create --name multiarch --use --driver-opt network=host

# Bootstrap
echo ""
echo "Bootstrapping builder..."
docker buildx inspect --bootstrap

echo ""
echo "========================================================"
echo "Builder reset complete!"
echo "========================================================"
echo ""
echo "Try your build again with ./build-test.sh or ./build-and-push.sh"
echo ""
