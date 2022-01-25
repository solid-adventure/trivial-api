require 'swagger_helper'

describe 'Credential Sets API' do

  include_context 'aws_credentials'

  path '/credential_sets' do

    let(:user) { FactoryBot.create(:user, :logged_in) }
    let('access-token') { user.tokens[client]['token_unhashed'] }
    let(:client) { user.tokens.keys.first }
    let(:expiry) { user.tokens[client]['expiry'] }
    let(:uid) { user.uid }

    let!(:existing_credential) { FactoryBot.create(:credential_set, user: user) }

    get 'Return a list of credential sets for the account' do
      security [{access_token: [], client: [], expiry: [], uid: []}]
      produces 'application/json'

      response '200', 'Credential sets returned' do
        schema type: :object, properties: {
          credential_sets: {
            type: :array,
            items: {
              type: :object,
              properties: {
                id: { type: :integer },
                name: { type: :string },
                credential_type: { type: :string }
              },
              required: ['id', 'name', 'credential_type']
            }
          }
        },
        required: ['credential_sets']
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['credential_sets'].length).to eq 1
          expect(data['credential_sets'].first['id']).to eq existing_credential.id
        end
      end
    end

    post 'Create a new credential set' do
      parameter name: :credential_set, in: :body, schema: {
        type: :object,
        properties: {
          credential_set: {
            type: :object,
            properties: {
              name: { type: :string },
              credential_type: { type: :string }
            },
            required: ['name', 'credential_type']
          },
          credentials: {
            type: :object
          }
        },
        required: ['credential_set']
      }
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

      response '200', 'Credential set created' do
        schema type: :object, properties: {
          credential_set: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              credential_type: { type: :string }
            },
            required: ['id', 'name', 'credential_type']
          }
        },
        required: ['credential_set']
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['credential_set']['name']).to eq credential_name
          expect(data['credential_set']['credential_type']).to eq credential_type
        end
      end
    end

  end

end
