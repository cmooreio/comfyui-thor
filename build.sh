#!/bin/bash
# Build and push ComfyUI Docker image for Jetson Thor
# Must be run ON psythor to ensure ARM64/Jetson compatibility
#
# Usage: ./build.sh [--push]
#
# Tags created:
#   - cmooreio/comfyui-thor:latest
#   - cmooreio/comfyui-thor:<git-commit-sha>
#   - cmooreio/comfyui-thor:comfyui-<version>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Docker Hub repository
REPO="cmooreio/comfyui-thor"

# Extract ComfyUI version from Dockerfile
COMFYUI_VERSION=$(grep -oP 'ARG COMFYUI_VERSION=\K[^\s]+' Dockerfile)
if [[ -z "$COMFYUI_VERSION" ]]; then
    echo "ERROR: Could not extract COMFYUI_VERSION from Dockerfile"
    exit 1
fi

# Get git commit SHA (short)
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Build tags (strip 'v' prefix from version for cleaner tag)
VERSION_TAG="${COMFYUI_VERSION#v}"
TAG_LATEST="${REPO}:latest"
TAG_SHA="${REPO}:${GIT_SHA}"
TAG_VERSION="${REPO}:${VERSION_TAG}"

echo "=============================================="
echo "Building ComfyUI Docker Image for Jetson Thor"
echo "=============================================="
echo "ComfyUI Version: ${COMFYUI_VERSION}"
echo "Git Commit:      ${GIT_SHA}"
echo ""
echo "Tags to be created:"
echo "  - ${TAG_LATEST}"
echo "  - ${TAG_SHA}"
echo "  - ${TAG_VERSION}"
echo "=============================================="
echo ""

# Build the image with all tags
docker build \
    --build-arg COMFYUI_VERSION="${COMFYUI_VERSION}" \
    -t "${TAG_LATEST}" \
    -t "${TAG_SHA}" \
    -t "${TAG_VERSION}" \
    .

echo ""
echo "Build complete!"
echo ""

# Push if requested
if [[ "${1:-}" == "--push" ]]; then
    echo "Pushing images to Docker Hub..."
    docker push "${TAG_LATEST}"
    docker push "${TAG_SHA}"
    docker push "${TAG_VERSION}"
    echo ""
    echo "Push complete!"
    echo "  ${TAG_LATEST}"
    echo "  ${TAG_SHA}"
    echo "  ${TAG_VERSION}"
else
    echo "To push to Docker Hub, run:"
    echo "  ./build.sh --push"
fi
