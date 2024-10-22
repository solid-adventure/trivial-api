#!/bin/bash

rails db:migrate
rails runner "CacheWarmUpJob.perform_now(cache_name: 'app_activity_stats', options: {delay_duration: 0})"
service cron start
rails server -b 0.0.0.0
