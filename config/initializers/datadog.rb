# frozen_string_literal: true

unless Rails.env.test?
  require 'ddtrace'

  Datadog.configure do |c|
    c.tracing.instrument :rails, service_name: 'trivial-api'
  end
end
