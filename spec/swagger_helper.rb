# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.swagger_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.swagger_docs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      paths: {},
      servers: [
        {
          url: '{defaultHost}',
          variables: {
            defaultHost: {
              default: 'https://trivial-api-staging.herokuapp.com/',
            }
          }
        },
      ],
      components: {
        securitySchemes: {
          access_token: {
            type: :apiKey,
            name: 'access-token',
            in: :header
          },
          client: {
            type: :apiKey,
            name: 'client',
            in: :header
          },
          expiry: {
            type: :apiKey,
            name: 'expiry',
            in: :header
          },
          uid: {
            type: :apiKey,
            name: 'uid',
            in: :header
          },
          app_api_key: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT'
          }
        },
        schemas: {
          chart_schema: {
            type: :object,
            properties: {
              id: { type: :integer },
              dashboard_id: { type: :integer },
              register_id: { type: :integer },
              name: { type: :string },
              chart_type: { type: :string },
              color_scheme: { type: :string },
              default_time_range: { type: :string },
              default_timezones: {
                type: :array,
                items: { type: :string }
              },
              time_range_bounds: {
                type: :object,
                additionalProperties: { type: :string }
              },
              report_period: { type: :string },
              report_groups: {
                type: :object,
                additionalProperties: { type: :boolean }
              }
            },
            required: %i[id dashboard_id register_id name chart_type color_scheme default_time_range default_timezones time_range_bounds report_period report_groups]
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The swagger_docs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.swagger_format = :yaml


  # save configured requests as examples
  config.after(:each, type: :request) do |example|
    request_example_name = example.metadata[:save_request_example]
    if request_example_name && respond_to?(request_example_name)
      param = example.metadata[:operation][:parameters].detect { |p| p[:name] == request_example_name }
      param[:schema][:example] = send(request_example_name)
    end
  end

  # save responses as examples
  config.after(:each, type: :request) do |example|
    example.metadata[:response][:content] = {
      'application/json' => {
        example: JSON.parse(response.body, symbolize_names: true)
      }
    }
  rescue JSON::ParserError
    # continue
  end
end
