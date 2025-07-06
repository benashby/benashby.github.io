# Create a Jekyll container from a Ruby Alpine image

# Use Ruby 2.7 for GitHub Pages compatibility (Jekyll 3.9.x)
FROM ruby:2.7-alpine3.15

# Add Jekyll dependencies to Alpine
RUN apk update
RUN apk add --no-cache build-base gcc cmake git

# Update RubyGems and install compatible versions for Ruby 2.7
RUN gem update --system 3.3.26 && \
    gem install bundler -v 2.4.22 && \
    gem install ffi -v 1.17.2 && \
    gem install jekyll -v "~>3.9.0"