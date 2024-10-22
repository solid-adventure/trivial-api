#!/bin/bash

rails db:migrate
echo "rails runner 'CacheWarmUpJob.perform_now(cache_name: \"app_activity_stats\", options: {delay_duration: 0})'" | at now
service cron start
rails server -b 0.0.0.0
