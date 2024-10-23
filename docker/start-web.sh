#!/bin/bash

# IMPORTANT Any tasks added here must complete in less than 30 seconds.
#           If you add a task that does not complete in that time frame
#           it will cause the container to be restarted in a loop.
#
#           Tasks that cannot complete in that timeframe must be run in the background.


# Run the cache warmup job in the background
# >> /proc/1/fd/1 2>&1) prints logs to STDOUT
# & runs the command in the background
rails runner 'CacheWarmUpJob.perform_now(cache_name: "app_activity_stats", options: {delay_duration: 0})' >> /proc/1/fd/1 2>&1 &

rails db:migrate
rails server -b 0.0.0.0
