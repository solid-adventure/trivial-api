require 'swagger_helper'

describe 'Credentials API' do

  include_context "jwt"
  include_context 'aws_credentials'

  path '/apps/{id}/credentials' do
    parameter name: :id, in: :path, type: :string

    patch 'Refresh an expired API key' do
      parameter name: :patch_request, in: :body, schema: {
        type: :object,
        properties: {
          path: { type: :array, items: { type: :string } },
          credentials: { type: :object,
            properties: {
              current_value: { type: :string },
              new_value: { type: :string }
            }
          }
        }
      }
      security [{app_api_key: []}]
      consumes 'application/json'
      produces 'application/json'

      let(:id) { '-' }
      let(:Authorization) { "Bearer #{key}" }
      let(:key) { calling_app.api_keys.issue! }
      let(:calling_app) { FactoryBot.create(:app) }
      let(:path) { ['1', '1', 'code_grant', 'access_token'] }
      let(:current_value) { 'secret' }
      let(:stored_value) { current_value }
      let(:new_value) { 'new secret' }
      let(:stored_credentials) {
        "{\"1\":{\"1\":{\"code_grant\":{\"access_token\":\"#{stored_value}\"}}}}"
      }
      let(:patch_request) { {
        path: path,
        credentials: {
          current_value: current_value, new_value: new_value
        }
      } }

      response '200', 'Single credential value updated' do
        schema type: :object, properties: {
          ok: { type: :boolean }
        }
        run_test!
      end

      response '401', 'Authentication failed' do
        let(:key) { 'eyJhbGciOiJub25lIn0.eyJhcHAiOiJhZjE3YTY1MjE0YWFiYSJ9.' }
        run_test!
      end

      response '400', 'Invalid path or incorrect stored value' do
        let(:stored_value) { 'old value' }
        run_test!
      end
    end
  end

end
