#!/bin/bash

rails db:schema:load
rails db:migrate
rails server -b 0.0.0.0