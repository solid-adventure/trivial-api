require 'swagger_helper'

describe 'Auth API' do

  include_context "aws_role"
  include_context "jwt"

  def self.user_profile_schema
    {
      type: :object,
      properties: {
        id: { type: :integer },
        provider: { type: :string },
        uid: { type: :string },
        name: { type: :string },
        email: { type: :string },
        created_at: { type: :string },
        updated_at: { type: :string },
        role: { type: :string },
        approval: { type: :string },
        color_theme: { type: :string, nullable: true },
        aws_role: { type: :string, nullable: true }
      },
      required: %w(id provider uid name email role approval)
    }
  end

  path '/auth' do

    post 'Register a user' do
      tags 'Auth'
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          password: { type: :string },
          name: { type: :string }
        },
        required: [ 'email', 'password', 'name' ]
      }

      let(:email) { 'jane.doe@example.test' }
      let(:password) { '5uperSecret!' }
      let(:name) { 'Jane Doe' }
      let(:user) { {
        email: email,
        password: password,
        name: name
      } }

      response '200', 'user created', save_request_example: :user do
        schema type: :object,
          properties: {
            status: { type: :string },
            data: user_profile_schema
          },
          required: %w(status data)

        run_test!
      end

      response '422', 'unprocessable entity - email taken; name, email, password blank or too short!' do
        let(:password) { '' }
        run_test!
      end
    end

  end

  path '/auth/sign_in' do

    post 'Sign in a user' do
      tags 'Auth'
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          password: { type: :string }
        },
        required: [ 'email', 'password' ]
      }

      let(:user) { { email: email, password: password } }
      let(:email) { existing_user.email }
      let(:password) { 'insecure' }
      let(:existing_user) { FactoryBot.create(:user) }

      response '200', 'user logged in', save_request_example: :user do
        schema type: :object, properties: {
          data: user_profile_schema
        }, required: ['data']

        run_test!
      end

      response '401', 'unauthorized - email or password is wrong' do
        let(:password) { 'invalid' }
        run_test!
      end
    end

  end

  path '/auth/sign_out' do

    delete 'Sign out a user' do
      tags 'Auth'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'

      let(:user) { FactoryBot.create(:user, :logged_in) }
      let('access-token') { user.tokens[client]['token_unhashed'] }
      let(:client) { user.tokens.keys.first }
      let(:expiry) { user.tokens[client]['expiry'] }
      let(:uid) { user.uid }

      response '200', 'user signed out' do
        schema type: :object, properties: {
          data: user_profile_schema
        }

        run_test!
      end

      response '404', 'unauthorized - invalid login credentials in the header' do
        let('access-token') { 'invalidtoken' }
        run_test!
      end

    end

  end

end
