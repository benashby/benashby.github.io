#!/bin/bash

# Run Jekyll server using Podman
echo "Starting Jekyll server with Podman..."
echo "The site will be available at http://localhost:4000"
echo "Press Ctrl+C to stop the server"

# Run the container with live reload
podman run --rm -it \
  -v $(pwd):/srv/jekyll:Z \
  -p 4000:4000 \
  -p 35729:35729 \
  jekyll-dev \
  sh -c "cd /srv/jekyll && bundle install && bundle exec jekyll serve --host 0.0.0.0 --livereload"