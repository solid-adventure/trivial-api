#!/bin/bash

# IMPORTANT Any tasks added here must complete in less than 30 seconds.
#           If you add a task that does not complete in that time frame
#           it will cause the container to be restarted in a loop.
#
#           Tasks that cannot complete in that timeframe must be run in the background.

rails db:migrate
rails server -b 0.0.0.0
