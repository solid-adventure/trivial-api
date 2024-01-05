#!/bin/bash

rails db:environment:set RAILS_ENV=production
rails db:schema:load
rails db:migrate
rails server -b 0.0.0.0