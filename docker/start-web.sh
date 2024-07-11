#!/bin/bash

# WARNING: uncomment once activity_entry_payload_keys v2 is successfully migrated
# rails db:migrate
rails server -b 0.0.0.0
