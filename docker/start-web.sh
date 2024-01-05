#!/bin/bash

rails db:create
rails db:migrate
rails server -b 0.0.0.0