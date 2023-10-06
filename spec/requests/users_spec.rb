require 'swagger_helper'

describe 'Users API' do

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

  path '/users' do

    get 'Show the list of the users' do
      tags 'User'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      response '200', 'users listed' do
        schema type: :object, properties: {
          users: {
            type: :array,
            items: user_schema
          }
        },
        required: ['users']

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['users'].length).to eq User.all.size
          expect(data['users'].map{ |u| u["id"] }).to eq User.all.pluck(:id)
        end
      end

      response '401', 'unauthorized or not an admin user' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end

    post 'Create a user' do
      tags 'User'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      parameter name: :new_user, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          email: { type: :string },
          password: { type: :string },
          role: { type: :string },
          approval: { type: :string }
        },
        required: [ 'email', 'password', 'name' ]
      }

      let(:email) { 'jane.doe@example.test' }
      let(:new_user) { {
        name: 'Jane Doe',
        email: email,
        password: 'supersecret',
        role: 'member',
        approval: 'approved'
      } }

      response '201', 'user created', save_request_example: :new_user do
        schema type: :object, properties: { user: user_schema }, required: ['user']
        run_test!
      end

      response '400', 'bad request' do
        let(:email) { '' }
        run_test!
      end

      response '401', 'unauthorized' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end

  end

  path '/users/{userId}' do
    let(:member) { FactoryBot.create(:user) }

    get 'Show the user with userId' do
      tags 'User'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      parameter name: "userId", in: :path, type: :string

      let(:userId) { member.id }

      response '200', 'show user' do
        schema type: :object, properties: { user: user_schema }, required: ['user']
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['user']['id']).to eq member.id
        end
      end

      response '404', 'No user found with that id' do
        let(:userId) { 'nonesuch' }
        run_test!
      end

      response '401', 'unauthorized' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end

    put 'Update the User with userId' do
      tags 'User'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      parameter name: "userId", in: :path, type: :string
      let(:userId) { member.id }
      parameter name: :user_data, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          email: { type: :string },
          password: { type: :string },
          role: { type: :string },
          approval: { type: :string }
        }
      }

      let(:user_data) { { name: 'New Name' } }

      response '200', 'user updated', save_request_example: :user_data do
        schema type: :object, properties: { user: user_schema }, required: ['user']
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['user']['name']).to eq 'New Name'
        end
      end

      response '400', 'bad request' do
        let(:user_data) { { name: '' } }
        run_test!
      end

      response '404', 'No user found with that id' do
        let(:userId) { 'nonesuch' }
        run_test!
      end

      response '401', 'unauthorized' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end

    delete 'Destroy the team with userId' do
      tags 'User'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      parameter name: "userId", in: :path, type: :string
      let(:userId) { member.id }

      response '204', 'user deleted' do
        run_test!
      end

      response '404', 'No user found with that id' do
        let(:userId) { 'nonesuch' }
        run_test!
      end

      response '401', 'unauthorized' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end
  end
end
