require 'swagger_helper'

describe 'Credential Sets API' do

  include_context "jwt"
  include_context 'aws_credentials'

  let(:user) { FactoryBot.create(:user, :logged_in) }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:client) { user.tokens.keys.first }
  let(:expiry) { user.tokens[client]['expiry'] }
  let(:uid) { user.uid }

  let!(:existing_credential) { FactoryBot.create(:credential_set, owner: user) }

  def self.credential_definition_schema
    {
      type: :object,
      properties: {
        credential_set: credential_set_input_object_type,
        credentials: { type: :object }
      },
      required: ['credential_set']
    }
  end

  def self.credential_update_schema
    {
      type: :object,
      properties: {
        credential_set: credential_set_input_object_type,
        credentials: { type: :object }
      }
    }
  end

  def self.credential_set_input_object_type
    {
      type: :object,
      properties: {
        name: { type: :string },
        credential_type: { type: :string }
      },
      required: ['name', 'credential_type']
    }
  end

  def self.credential_set_response_schema
    {
      type: :object,
      properties: {
        credential_set: credential_set_response_object_type
      },
      required: ['credential_set']
    }
  end

  def self.credential_set_response_object_type
    {
      type: :object,
      properties: {
        id: { type: :string },
        name: { type: :string },
        credential_type: { type: :string }
      },
      required: ['id', 'name', 'credential_type']
    }
  end

  path '/credential_sets' do

    get 'Return a list of credential sets for the account' do
      tags 'Credential Sets'
      security [{access_token: [], client: [], expiry: [], uid: []}]
      produces 'application/json'

      response '200', 'Credential sets returned' do
        schema type: :object, properties: {
          credential_sets: {
            type: :array,
            items: credential_set_response_object_type
          }
        },
        required: ['credential_sets']
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['credential_sets'].length).to eq 1
          expect(data['credential_sets'].first['id']).to eq existing_credential.external_id
        end
      end
    end

    post 'Create a new credential set' do
      tags 'Credential Sets'
      parameter name: :credential_set, in: :body, schema: credential_definition_schema
      security [{access_token: [], client: [], expiry: [], uid: []}]
      consumes 'application/json'
      produces 'application/json'

      let(:credential_name) { 'Mailgun' }
      let(:credential_type) { 'MailgunCredentials' }
      let(:credentials) { {api_key: '+7Ucdca1LUQ=', domain: 'example.test'} }
      let(:credential_set) { {
        credential_set: {
          name: credential_name,
          credential_type: credential_type
        },
        credentials: credentials
      } }

      response '200', 'Credential set created', save_request_example: :credential_set do
        schema credential_set_response_schema
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['credential_set']['name']).to eq credential_name
          expect(data['credential_set']['credential_type']).to eq credential_type
        end
      end

      response '422', 'Invalid credential set body' do
        let(:credential_name) { nil }
        run_test!
      end
    end

  end

  path '/credential_sets/{set_id}' do
    parameter name: :set_id, in: :path, type: :string

    let(:set_id) { existing_credential.external_id }
    let(:stored_credentials) {
      "{\"account_sid\":\"fa8f7fa53659d6de\",\"auth_token\":\"Whe8Y5poyQo=\"}"
    }

    get 'Access the credential data for a set' do
      tags 'Credential Sets'
      security [{access_token: [], client: [], expiry: [], uid: []}]
      produces 'application/json'

      response '200', 'Credential data returned for set' do
        schema type: :object, properties: {
          credential_set: credential_set_response_object_type,
          credentials: { type: :object }
        },
        required: ['credential_set', 'credentials']
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['credentials']).to eq JSON.parse(stored_credentials)
        end
      end

      response '404', 'Incorrect id' do
        let(:set_id) { 'invalid' }
        run_test!
      end
    end

    put 'Update the credential set and/or its credential data' do
      tags 'Credential Sets'
      parameter name: :credential_set, in: :body, schema: credential_update_schema
      security [{access_token: [], client: [], expiry: [], uid: []}]
      consumes 'application/json'
      produces 'application/json'

      let(:credential_name) { 'New Name' }
      let(:credential_type) { existing_credential.credential_type }
      let(:credentials) { {account_sid: 'fa8f7fa53659d6de', auth_token: 'Whe8Y5poyQo='} }
      let(:credential_set) { {
        credential_set: {
          name: credential_name,
          credential_type: credential_type
        },
        credentials: credentials
      } }

      response '200', 'Credentials updated', save_request_example: :credential_set do
        schema credential_set_response_schema
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['credential_set']['name']).to eq credential_name
          expect(data['credential_set']['credential_type']).to eq credential_type
        end
      end

      response '422', 'Invalid credential set body' do
        let(:credential_name) { nil }
        run_test!
      end

      response '404', 'Incorrect id' do
        let(:set_id) { 'invalid' }
        run_test!
      end
    end

    patch 'Update a single value within the credential data for a set' do
      tags 'Credential Sets'
      parameter name: :credential_set, in: :body, schema: {
        type: :object,
        properties: {
          path: { type: :array, items: :string },
          credentials: {
            type: :object,
            properties: {
              current_value: { type: :string },
              new_value: { type: :string }
            },
            required: ['current_value', 'new_value']
          }
        },
        required: ['path', 'credentials']
      }
      security [{app_api_key: []}]
      consumes 'application/json'
      produces 'application/json'

      let(:Authorization) { "Bearer #{key}" }
      let(:key) { user_app.api_keys.issue! }
      let(:user_app) { FactoryBot.create(:app, owner: user) }
      let(:path) { ['code_grant', 'access_token'] }
      let(:current_value) { 'Whe8Y5poyQo=' }
      let(:new_value) { 'zTeYlkd9yzo=' }
      let(:stored_value) { current_value }
      let(:stored_credentials) {
        "{\"code_grant\":{\"access_token\":\"#{stored_value}\"}}"
      }
      let(:credential_set) { {
        path: path,
        credentials: {
          current_value: current_value,
          new_value: new_value
        }
      } }

      response '200', 'Credentials updated', save_request_example: :credential_set do
        schema({type: :object, properties: { ok: {type: :boolean} }, required: ['ok']})
        run_test!
      end

      response '422', 'Invalid path or current value' do
        let(:stored_value) { 'somethingelse' }
        run_test!
      end

      response '404', 'Incorrect id' do
        let(:set_id) { 'invalid' }
        run_test!
      end

      response '401', 'Invalid or missing API key' do
        let(:key) { 'eyJhbGciOiJub25lIn0.eyJhcHAiOiJhZjE3YTY1MjE0YWFiYSJ9.' }
        run_test!
      end
    end

    delete 'Delete the credential set and its credential data' do
      tags 'Credential Sets'
      security [{access_token: [], client: [], expiry: [], uid: []}]
      produces 'application/json'

      response '200', 'Credentials deleted' do
        run_test!
      end

      response '404', 'Incorrect id' do
        let(:set_id) { 'invalid' }
        run_test!
      end
    end
  end

  path '/credential_sets/{set_id}/api_key' do
    parameter name: :set_id, in: :path, type: :string

    let(:set_id) { existing_credential.external_id }

    put 'Refresh an expired API key' do
      tags 'Credential Sets'
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
      let(:user_app) { FactoryBot.create(:app, owner: user) }
      let(:stored_path) { {path: 'api_key'} }
      let(:stored_key) { key }
      let(:stored_credentials) { "{\"api_key\":\"#{stored_key}\"}" }

      response '200', 'New API key issued and stored in credentials', save_request_example: :stored_path do
        schema type: :object, properties: {
          api_key: { type: :string },
          required: ['api_key']
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
