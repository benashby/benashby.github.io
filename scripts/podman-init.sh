#!/bin/bash

# Initialize Jekyll site with GitHub Pages compatible dependencies
echo "Initializing Jekyll site with GitHub Pages compatible dependencies..."

# Run the container to create initial Gemfile.lock
podman run --rm -it \
  -v $(pwd):/srv/jekyll:Z \
  jekyll-dev \
  sh -c "cd /srv/jekyll && bundle init --gemspec"

echo "Jekyll site initialized successfully!"