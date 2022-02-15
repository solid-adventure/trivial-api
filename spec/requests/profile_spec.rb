require 'swagger_helper'

describe 'Profile API' do

  let(:user) { FactoryBot.create(:user, :logged_in, role: :admin) }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:client) { user.tokens.keys.first }
  let(:expiry) { user.tokens[client]['expiry'] }
  let(:uid) { user.uid }

  def self.user_schema
    {
      type: :object,
      properties: {
        id: { type: :integer },
        name: { type: :string },
        email: { type: :string },
        role: { type: :string },
        approval: { type: :string },
        color_theme: { type: :string, nullable: true },
        created_at: { type: :string }
      },
      required: %w(id name email role approval)
    }
  end

  path '/profile' do
    get 'Show the logged in user\'s profile' do
      tags 'Profile'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      response '200', 'Current profile' do
        schema type: :object, properties: { user: user_schema }, required: ['user']
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['user']['id']).to eq user.id
        end
      end

      response '401', 'Not authorized' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end

    put 'Update the logged in user\'s profile' do
      tags 'Profile'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      parameter name: :profile, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          color_theme: { type: :string }
        }
      }

      let(:profile) { { name: new_name, color_theme: new_color_theme } }
      let(:new_name) { 'My New Name' }
      let(:new_color_theme ) { 'Light' }

      response '200', 'Profile updated', save_request_example: :profile do
        schema type: :object, properties: { user: user_schema }, required: ['user']
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['user']['name']).to eq new_name
          expect(data['user']['color_theme']).to eq new_color_theme
        end
      end

      response '400', 'Bad request' do
        let(:new_name) { '' }
        run_test!
      end

      response '401', 'Not authorized' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end
  end

end
