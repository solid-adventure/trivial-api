# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
require "#{Rails.root}/lib/services/kafka"


# Long-lived session shared by all requests
KAFKA = Services::Kafka.new