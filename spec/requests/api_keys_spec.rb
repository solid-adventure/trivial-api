require 'swagger_helper'

describe 'API Key API' do

  include_context "jwt"
  include_context 'aws_credentials'

  path '/apps/{id}/api_key' do
    parameter name: :id, in: :path, type: :string

    let(:id) { user_app.name }
    let(:user_app) { FactoryBot.create(:app, user: user) }
    let(:user) { FactoryBot.create(:user, :logged_in) }

    post 'Obtain a new API key' do
      tags 'API Keys'
      security [{access_token: [], client: [], expiry: [], uid: []}]
      produces 'application/json'

      let('access-token') { user.tokens[client]['token_unhashed'] }
      let(:client) { user.tokens.keys.first }
      let(:expiry) { user.tokens[client]['expiry'] }
      let(:uid) { user.uid }

      response '200', 'API key issued' do
        schema type: :object, properties: {
          api_key: { type: :string }
        }
        run_test!
      end
    end

    put 'Refresh an expired API key' do
      tags 'API Keys'
      parameter name: :stored_path, in: :body, schema: {
        type: :object, properties: {
          path: { type: :string }
        }
      }
      security [{app_api_key: []}]
      consumes 'application/json'
      produces 'application/json'

      let(:Authorization) { "Bearer #{key}" }
      let(:key) { user_app.api_keys.issue! }
      let(:stored_path) { {path: '1.1'} }
      let(:stored_key) { key }
      let(:stored_credentials) { "{\"1\":{\"1\":\"#{stored_key}\"}}" }

      response '200', 'New API key issued and stored in credentials' do
        schema type: :object, properties: {
          api_key: { type: :string }
        }
        run_test!
      end

      response '401', 'Authentication failed' do
        let(:key) { 'eyJhbGciOiJub25lIn0.eyJhcHAiOiJhZjE3YTY1MjE0YWFiYSJ9.' }
        run_test!
      end

      response '409', 'API key does not match key stored in credentials' do
        let(:stored_key) { 'x.y.z' }
        run_test!
      end
    end
  end
end
