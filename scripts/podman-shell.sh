#!/bin/bash

# Open an interactive shell in the Jekyll container
echo "Opening interactive shell in Jekyll container..."

# Run the container with an interactive shell
podman run --rm -it \
  -v $(pwd):/srv/jekyll:Z \
  -p 4000:4000 \
  -p 35729:35729 \
  jekyll-dev \
  sh -c "cd /srv/jekyll && bundle install && /bin/sh"