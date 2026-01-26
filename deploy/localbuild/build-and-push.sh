#!/bin/bash
# =============================================================================
# Build and Push Multi-Architecture Docker Image to GHCR
# =============================================================================
# DocuSeal Plus - Builds both AMD64 and ARM64 images locally
# Best run on an ARM laptop (native ARM64, emulated AMD64)
#
# Usage: ./build-and-push.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# =============================================================================
# Load credentials from keys.yml
# =============================================================================
KEYS_FILE="$SCRIPT_DIR/keys.yml"

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

# Parse YAML (simple grep-based parsing)
parse_yaml() {
    local key=$1
    grep "^${key}:" "$KEYS_FILE" | sed "s/^${key}:[[:space:]]*//" | tr -d '"' | tr -d "'"
}

GITHUB_USERNAME=$(parse_yaml "github_username")
GITHUB_PAT=$(parse_yaml "github_pat")
REGISTRY=$(parse_yaml "registry")
OWNER=$(parse_yaml "owner")
IMAGE_NAME=$(parse_yaml "image_name")

# Validate credentials
if [ -z "$GITHUB_USERNAME" ] || [ "$GITHUB_USERNAME" = "your-github-username" ]; then
    echo "Error: Invalid github_username in keys.yml"
    exit 1
fi

if [ -z "$GITHUB_PAT" ] || [[ "$GITHUB_PAT" == ghp_x* ]]; then
    echo "Error: Invalid github_pat in keys.yml (still contains placeholder)"
    exit 1
fi

# Build image path (all lowercase for GHCR)
REGISTRY="${REGISTRY:-ghcr.io}"
OWNER="${OWNER:-speedbitsinfinitytools}"
IMAGE_NAME="${IMAGE_NAME:-docuseal-plus}"
IMAGE="${REGISTRY}/${OWNER}/${IMAGE_NAME}"

# =============================================================================
# Get current version from VERSION file
# =============================================================================
VERSION_FILE="$PROJECT_ROOT/VERSION"

if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: VERSION file not found at $VERSION_FILE"
    exit 1
fi

CURRENT_VERSION=$(cat "$VERSION_FILE" | tr -d '\n' | tr -d ' ')

# Parse version parts (format: MAJOR.MINOR.PATCH.BUILD)
IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"
BUILD="${VERSION_PARTS[3]:-0}"

# Calculate next build version (only increment 4th digit)
NEXT_BUILD=$((BUILD + 1))
NEXT_VERSION="${MAJOR}.${MINOR}.${PATCH}.${NEXT_BUILD}"
BASE_VERSION="${MAJOR}.${MINOR}.${PATCH}"

# =============================================================================
# Display menu
# =============================================================================
echo ""
echo "========================================================"
echo "DocuSeal Plus - Build and Push (Multi-Arch)"
echo "========================================================"
echo ""
echo "Image:        $IMAGE"
echo "Source:       $PROJECT_ROOT"
echo "Current:      $CURRENT_VERSION"
echo "Base version: $BASE_VERSION (upstream DocuSeal)"
echo ""
echo "Select build type:"
echo ""
echo "  1) Dev build"
echo "     Tags: dev-YYYYMMDD-SHA"
echo "     No version increment"
echo ""
echo "  2) Latest build"
echo "     Tags: latest + dev-YYYYMMDD-SHA"
echo "     No version increment"
echo ""
echo "  3) Release build"
echo "     Tags: latest + $BASE_VERSION + $NEXT_VERSION"
echo "     Auto-increments version: $CURRENT_VERSION -> $NEXT_VERSION"
echo "     Updates VERSION file"
echo ""
read -p "Select option (1-3): " BUILD_TYPE

case $BUILD_TYPE in
    1)
        VERSION="dev-$(date +'%Y%m%d')-$(git rev-parse --short HEAD)"
        TAG_LATEST=false
        TAG_BASE=false
        UPDATE_VERSION=false
        echo ""
        echo "Dev build: $VERSION"
        ;;
    2)
        VERSION="dev-$(date +'%Y%m%d')-$(git rev-parse --short HEAD)"
        TAG_LATEST=true
        TAG_BASE=false
        UPDATE_VERSION=false
        echo ""
        echo "Latest build: $VERSION (+ latest tag)"
        ;;
    3)
        VERSION="$NEXT_VERSION"
        TAG_LATEST=true
        TAG_BASE=true
        UPDATE_VERSION=true
        echo ""
        echo "Release build: $VERSION (+ latest + $BASE_VERSION tags)"
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

# =============================================================================
# Build Summary and Confirmation
# =============================================================================
echo ""
echo "========================================================"
echo "Build Summary"
echo "========================================================"
echo ""
echo "Version:        $VERSION"
echo "Platforms:      linux/amd64, linux/arm64"
echo "Tag latest:     $TAG_LATEST"
echo "Tag base:       $TAG_BASE (-> $BASE_VERSION)"
echo "Update VERSION: $UPDATE_VERSION"
echo ""

read -p "Proceed with build and push? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# =============================================================================
# Update VERSION file if this is a release
# =============================================================================
if [ "$UPDATE_VERSION" = true ]; then
    echo ""
    echo "Updating VERSION file to $VERSION..."
    echo "$VERSION" > "$VERSION_FILE"
    echo "   Updated $VERSION_FILE"
fi

# Create .version file for Docker build
echo "$VERSION" > .version

# =============================================================================
# Login to GHCR
# =============================================================================
echo ""
echo "Logging in to $REGISTRY..."
echo "$GITHUB_PAT" | docker login "$REGISTRY" -u "$GITHUB_USERNAME" --password-stdin

# =============================================================================
# Check buildx setup
# =============================================================================
if ! docker buildx inspect multiarch > /dev/null 2>&1; then
    echo ""
    echo "Error: Buildx not set up. Run ./setup.sh first."
    exit 1
fi

docker buildx use multiarch

# =============================================================================
# Build Docker images (both architectures)
# =============================================================================
echo ""
echo "========================================================"
echo "Building Docker images (AMD64 + ARM64)..."
echo "========================================================"
echo ""
echo "This may take 30-60 minutes..."
echo "  - ARM64: Native build (fast)"
echo "  - AMD64: Emulated build (slower)"
echo ""
echo "If you get EOF errors, try recreating the builder:"
echo "  docker buildx rm multiarch && ./setup.sh"
echo ""

read -p "Recreate builder before build? (recommended if previous build failed) (y/N): " RECREATE_BUILDER
if [[ "$RECREATE_BUILDER" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Recreating buildx builder..."
    docker buildx rm multiarch 2>/dev/null || true
    docker buildx create --name multiarch --use
    docker buildx inspect --bootstrap
fi

START_TIME=$(date +%s)

# Build tag arguments
TAGS="-t ${IMAGE}:${VERSION}"

if [ "$TAG_LATEST" = true ]; then
    TAGS="$TAGS -t ${IMAGE}:latest"
fi

if [ "$TAG_BASE" = true ]; then
    TAGS="$TAGS -t ${IMAGE}:${BASE_VERSION}"
fi

# Build and push both architectures with plain progress (more stable)
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    $TAGS \
    -f Dockerfile \
    --progress=plain \
    --push \
    .

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "========================================================"
echo "Build and push complete!"
echo "========================================================"
echo ""
echo "Duration: ${MINUTES}m ${SECONDS}s"
echo ""
echo "Published images:"
echo "   ${IMAGE}:${VERSION}"
if [ "$TAG_LATEST" = true ]; then
    echo "   ${IMAGE}:latest"
fi
if [ "$TAG_BASE" = true ]; then
    echo "   ${IMAGE}:${BASE_VERSION}"
fi
echo ""
echo "Platforms: linux/amd64, linux/arm64"
echo ""
echo "Pull commands:"
echo "   docker pull ${IMAGE}:latest"
echo "   docker pull ${IMAGE}:${VERSION}"
echo ""
echo "View on GitHub:"
echo "   https://github.com/orgs/${OWNER}/packages/container/package/${IMAGE_NAME}"
echo ""

if [ "$UPDATE_VERSION" = true ]; then
    echo "Remember to commit the version update:"
    echo "   git add VERSION .version"
    echo "   git commit -m 'Release $VERSION'"
    echo "   git tag v$VERSION"
    echo "   git push && git push --tags"
    echo ""
fi
