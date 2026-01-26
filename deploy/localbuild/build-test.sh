#!/bin/bash
# =============================================================================
# Test Build Script for DocuSeal Plus
# =============================================================================
# Builds Docker images locally without pushing to verify everything works
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "========================================================"
echo "DocuSeal Plus - Test Build"
echo "========================================================"
echo ""
echo "Project: $PROJECT_ROOT"
echo ""

# Check buildx setup
if ! docker buildx inspect multiarch > /dev/null 2>&1; then
    echo "Error: Buildx not set up. Run ./setup.sh first."
    exit 1
fi

docker buildx use multiarch

# Create test version file
echo "test-$(date +'%Y%m%d')" > .version

echo "Select test type:"
echo ""
echo "  1) ARM64 only (native on ARM laptop - fast)"
echo "  2) AMD64 only (emulated on ARM laptop - slower)"
echo "  3) Both architectures"
echo "  4) AMD64 with fresh builder (fixes timeout issues)"
echo ""
read -p "Select option (1-4): " TEST_TYPE

case $TEST_TYPE in
    1)
        PLATFORMS="linux/arm64"
        FRESH_BUILDER=false
        echo ""
        echo "Building ARM64 (native)..."
        ;;
    2)
        PLATFORMS="linux/amd64"
        FRESH_BUILDER=false
        echo ""
        echo "Building AMD64 (emulated)..."
        ;;
    3)
        PLATFORMS="linux/amd64,linux/arm64"
        FRESH_BUILDER=false
        echo ""
        echo "Building both architectures..."
        ;;
    4)
        PLATFORMS="linux/amd64"
        FRESH_BUILDER=true
        echo ""
        echo "Building AMD64 with fresh builder (fixes EOF errors)..."
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

# Recreate builder if requested (fixes connection timeout issues)
if [ "$FRESH_BUILDER" = true ]; then
    echo ""
    echo "Recreating buildx builder to fix connection issues..."
    docker buildx rm multiarch 2>/dev/null || true
    docker buildx create --name multiarch --use
    docker buildx inspect --bootstrap
fi

echo ""
echo "========================================================"
echo "Starting build..."
echo "========================================================"
echo ""
echo "This may take 10-30 minutes depending on your machine."
echo "For AMD64 emulated builds, 30-60 minutes is normal."
echo ""

START_TIME=$(date +%s)

# Build without pushing (--load only works for single platform)
if [ "$TEST_TYPE" = "3" ]; then
    # Multi-platform: just build, don't load
    docker buildx build \
        --platform "$PLATFORMS" \
        -t docuseal-plus:test \
        -f Dockerfile \
        --progress=plain \
        .
else
    # Single platform: build and load locally
    docker buildx build \
        --platform "$PLATFORMS" \
        -t docuseal-plus:test \
        -f Dockerfile \
        --progress=plain \
        --load \
        .
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "========================================================"
echo "Build complete!"
echo "========================================================"
echo ""
echo "Duration: ${MINUTES}m ${SECONDS}s"
echo "Platform: $PLATFORMS"
echo ""

if [ "$TEST_TYPE" != "3" ]; then
    echo "Image loaded locally as: docuseal-plus:test"
    echo ""
    echo "To test run:"
    echo "  docker run --rm -p 3000:3000 docuseal-plus:test"
    echo ""
fi

echo "Ready to build and push? Run:"
echo "  ./build-and-push.sh"
echo ""
