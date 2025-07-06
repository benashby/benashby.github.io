#!/bin/bash

# Build the Jekyll development container using Podman
echo "Building Jekyll development container with Podman..."

# Build the container image
podman build -t jekyll-dev -f dockerfile .

echo "Container image built successfully!"
echo "Run ./scripts/podman-serve.sh to start the Jekyll server"