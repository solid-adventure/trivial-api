require 'swagger_helper'

describe 'Webhooks API' do

  include_context 'app_proxy_requests'

  let(:user) { FactoryBot.create(:user, :logged_in, role: :admin) }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:client) { user.tokens.keys.first }
  let(:expiry) { user.tokens[client]['expiry'] }
  let(:uid) { user.uid }
  let!(:user_app) { FactoryBot.create(:app, user: user) }

  def self.webhook_schema
    {
      type: :object,
      properties: {
        app_id: { type: :string },
        update_id: { type: :string, nullable: true },
        activity_type: { type: :string },
        status: { type: :string, nullable: true },
        source: { type: :string },
        payload: { type: :object, nullable:true },
        diagnostics: { type: :object, nullable: true }
      }, required: ['app_id', 'source', 'payload']
    }
  end

  def self.request_status_schema
    {
      type: :object,
      properties: {
        status: { type: :integer },
        message: { type: :string }
      }, required: ['status', 'message']
    }
  end

  path '/webhooks' do
    get 'Retrieve the list of logged requests' do
      tags 'Activity'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'application/json'
      parameter name: 'app_id', in: :query, required: true
      parameter name: 'limit', in: :query, required: false

      let(:app_id) { user_app.name }
      let(:limit) { 10 }
      let!(:build_entry) { FactoryBot.create(:activity_entry, :build, user: user, app: user_app) }
      let!(:request_entry) { FactoryBot.create(:activity_entry, :request, user: user, app: user_app) }

      response '200', 'Request listing returned' do
        schema type: :array, items: webhook_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq 1
          expect(data.first['id']).to eq request_entry.id
        end
      end
    end

    post 'Log the start of a request' do
      tags 'Activity'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :new_webhook, in: :body, schema: {
        type: :object,
        properties: {
          app_id: { type: :string },
          status: { type: :string },
          source: { type: :string },
          payload: { type: :object },
          diagnostics: { type: :object }
        },
        required: [ 'app_id', 'source', 'payload' ]
      }
      let(:payload) { {"test_data" => "12345"} }
      let(:new_webhook) { {
        app_id: user_app.name,
        source: 'localhost',
        payload: payload.to_json
      } }

      response '201', 'Request logged', save_request_example: :new_webhook do
        schema type: :object, properties: {
            app_id: { type: :string },
            update_id: { type: :string },
            activity_type: { type: :string },
            status: { type: :string, nullable: true },
            source: { type: :string },
            payload: { type: :object, nullable:true },
            diagnostics: { type: :object, nullable: true }
          }, required: ['app_id', 'update_id', 'source', 'payload']

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['app_id']).to eq user_app.name
          expect(data['activity_type']).to eq 'request'
          expect(data['source']).to eq new_webhook[:source]
          expect(data['payload']).to eq payload
        end
      end
    end
  end

  path '/webhooks/{webhookId}' do
    get 'Retrieve the details of a single request log' do
      tags 'Activity'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'application/json'
      parameter name: "webhookId", in: :path, type: :string

      let!(:request_entry) { FactoryBot.create(:activity_entry, :request, user: user, app: user_app) }
      let(:webhookId) { request_entry.id }

      response '200', 'Request log details returned' do
        schema webhook_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['id']).to eq request_entry.id
        end
      end
    end

    put 'Update a request log with status and diagnostics' do
      tags 'Activity'
      consumes 'application/json'
      produces 'application/json'
      parameter name: "webhookId", in: :path, type: :string

      let!(:request_entry) { FactoryBot.create(:activity_entry, :request, user: user, app: user_app, status: nil, diagnostics: nil, duration_ms: nil) }
      let(:webhookId) { request_entry.update_id }

      parameter name: :webhook_properties, in: :body, schema: {
        type: :object,
        properties: {
          status: { type: :string },
          duration_ms: { type: :integer },
          diagnostics: { type: :object }
        },
        required: [ 'status' ]
      }
      let(:webhook_properties) { {
        status: '500',
        duration_ms: 2471,
        diagnostics: {
          "errors" => [{
            "name" => "FetchError",
            "stack" => "FetchError: request to http://localhost:5000/bogus failed, reason: connect ECONNREFUSED 127.0.0.1:5000\n    at processTicksAndRejections (internal/process/task_queues.js:84:21)"
          }],
          "events" => [{
            "event" => "POST",
            "detail" => {
              "url" => "http://localhost:5000/bogus",
              "body" => "{}",
              "method" => "POST",
              "headers" => {"Content-Type" => "application/json"}
            },
            "success" => true
          }]
        }
      } }

      response '200', 'Request log updated', save_request_example: :webhook_properties do
        schema webhook_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq webhook_properties[:status]
          expect(data['diagnostics']).to eq webhook_properties[:diagnostics]
        end
      end
    end
  end

  path '/webhooks/{appId}/send' do
    post 'Send a request to an app' do
      tags 'Activity'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      produces 'application/json'
      parameter name: "appId", in: :path, type: :string

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          payload: { type: :object }
        },
        required: ['payload']
      }

      let(:appId) { user_app.name }
      let(:payload) { { payload: {test_data: "12345"} } }

      response '200', 'Request sent' do
        schema request_status_schema
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq app_status_code.to_i
          expect(data['message']).to eq app_status_message
          expect(ActivityEntry).to have_received(:post).with(
            URI(user_app.url) + "/webhooks/receive",
            payload[:payload].to_json,
            'Content-Type' => 'application/json'
          )
        end
      end
    end
  end

  path '/webhooks/{webhookId}/resend' do
    post 'Re-send the payload from a request to an app' do
      tags 'Activity'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'application/json'
      parameter name: "webhookId", in: :path, type: :string

      let!(:request_entry) { FactoryBot.create(:activity_entry, :request, user: user, app: user_app) }
      let(:webhookId) { request_entry.id }

      response '200', 'Request re-sent' do
        schema request_status_schema
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq app_status_code.to_i
          expect(data['message']).to eq app_status_message
          expect(ActivityEntry).to have_received(:post).with(
            URI(user_app.url) + "/webhooks/receive",
            request_entry.payload.to_json,
            'Content-Type' => 'application/json',
            'X-Trivial-Original-Id' => request_entry.id.to_s
          )
        end
      end
    end
  end

  path '/webhooks/{appId}/send' do
    post 'Send a request with payload containing null values' do
      tags 'Activity'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      produces 'application/json'
      parameter name: "appId", in: :path, type: :string

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          payload: { type: :object }
        },
        required: ['payload']
      }

      let(:appId) { user_app.name }
      let(:payload) { { payload: {test_data: "12345", list_with_nulls: [nil, "null"]} } }

      response '200', 'Request sent' do
        schema request_status_schema
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq app_status_code.to_i
          expect(data['message']).to eq app_status_message
          expect(ActivityEntry).to have_received(:post).with(
            URI(user_app.url) + "/webhooks/receive",
            payload[:payload].to_json,
            'Content-Type' => 'application/json'
          )
        end
      end
    end
  end

end
