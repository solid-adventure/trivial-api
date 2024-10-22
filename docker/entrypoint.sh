#!/bin/bash
# from https://github.com/docker/awesome-compose/tree/master/official-documentation-samples/rails/
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /usr/src/app/tmp/pids/server.pid

# Start atd daemon
atd

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
