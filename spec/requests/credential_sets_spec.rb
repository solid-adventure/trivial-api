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
        run_test!
      end
    end

  end

end
