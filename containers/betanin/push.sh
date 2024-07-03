#!/bin/bash

# Variables
IMAGE_NAME="profmoo/betanin"
VERSION="latest"
GHCR_IO="ghcr.io"

# Build the Docker image for x86_64 arch
docker buildx build --platform linux/amd64 -t ${GHCR_IO}/${IMAGE_NAME}:${VERSION} .

# Push the Docker image to GitHub Container Registry
docker push ${GHCR_IO}/${IMAGE_NAME}:${VERSION}
