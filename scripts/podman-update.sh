#!/bin/bash

# Update Jekyll dependencies in the container
echo "Updating Jekyll dependencies..."

# Run bundle update in the container
podman run --rm -it \
  -v $(pwd):/srv/jekyll:Z \
  jekyll-dev \
  sh -c "cd /srv/jekyll && bundle install && bundle update"

echo "Dependencies updated successfully!"