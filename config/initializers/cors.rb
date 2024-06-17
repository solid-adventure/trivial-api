# frozen_string_literal: true
# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV['TRIVIAL_UI_URL']&.split(',') || ''

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],

      expose: [
        'access-token',
        'client',
        'expiry',
        'uid'
      ]
  end
  origins = all_resources[0].instance_variable_get(:@origins)
  if origins.empty?
    puts 'Not accepting requests from Trivial UI: No URL provided, set TRIVIAL_UI_URL to enable CORS'
  else
    puts "Accepting requests from Trivial UI from: #{ origins }"
  end
end
