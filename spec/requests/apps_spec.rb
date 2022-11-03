require 'swagger_helper'

describe 'Apps API' do

  let(:user) { FactoryBot.create(:user, :logged_in, role: :admin) }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:client) { user.tokens.keys.first }
  let(:expiry) { user.tokens[client]['expiry'] }
  let(:uid) { user.uid }
  let!(:user_app) { FactoryBot.create(:app, user: user) }

  def self.app_schema
    {
      type: :object,
      properties: {
        id: { type: :integer },
        name: { type: :string },
        created_at: { type: :string },
        updated_at: { type: :string },
        hostname: { type: :string },
        domain: { type: :string },
        load_balancer: { type: :string },
        descriptive_name: { type: :string },
        aws_role: { type: :string }
      },
      required: %w(id name created_at updated_at hostname domain load_balancer descriptive_name)
    }
  end

  path '/apps' do
    get 'List the current user\'s applications' do
      tags 'Apps'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'application/json'

      response '200', 'App listing' do
        schema type: :array, items: app_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq 1
          expect(data.first['name']).to eq user_app.name
        end
      end

      # Disable to allow public views
      response '401', 'Invalid credentials' do
        let('access-token') { 'invalid-token' }
        run_test!
      end

    end

    post 'Create a new application' do
      tags 'Apps'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :new_app, in: :body, schema: {
        type: :object,
        properties: {
          descriptive_name: { type: :string }
        },
        required: [ 'descriptive_name' ]
      }
      let(:descriptive_name) { 'A Test' }
      let(:new_app) { { descriptive_name: descriptive_name } }

      response '200', 'App created', save_request_example: :new_app do
        schema type: app_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['descriptive_name']).to eq descriptive_name
        end
      end

      response '422', 'Missing or invalid field' do
        let(:descriptive_name) { '' }
        run_test!
      end

      response '401', 'Invalid credentials' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end
  end

  path '/apps/{appId}' do
    get 'Retrieve details for the app with the given id (name field)' do
      tags 'Apps'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'application/json'
      parameter name: "appId", in: :path, type: :string

      let(:appId) { user_app.name }

      response '200', 'App details' do
        schema app_schema
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['id']).to eq user_app.id
          expect(data['name']).to eq user_app.name
          expect(data['descriptive_name']).to eq user_app.descriptive_name
        end
      end

      response '401', 'No app found for the current user with that id' do
        let(:appId) { 'invalid' }
        run_test!
      end

      # Disable to allow public views
      response '401', 'Invalid credentials' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end

    put 'Update the app' do
      tags 'Apps'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      produces 'application/json'
      parameter name: "appId", in: :path, type: :string

      let(:appId) { user_app.name }

      parameter name: :app_updates, in: :body, schema: {
        type: :object,
        properties: {
          descriptive_name: { type: :string }
        }
      }
      let(:descriptive_name) { 'A New Name' }
      let(:app_updates) { { descriptive_name: descriptive_name } }

      response '200', 'App updated', save_request_example: :app_updates do
        schema app_schema
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['descriptive_name']).to eq descriptive_name
        end
      end

      response '401', 'No app found for the current user with that id' do
        let(:appId) { 'invalid' }
        run_test!
      end

      response '422', 'Missing or invalid field' do
        let(:descriptive_name) { '' }
        run_test!
      end

      response '401', 'Invalid credentials' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end

    delete 'Delete the app' do
      tags 'Apps'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      parameter name: "appId", in: :path, type: :string

      let(:appId) { user_app.name }

      response '200', 'App deleted' do
        run_test!
      end

      response '401', 'No app found for the current user with that id' do
        let(:appId) { 'invalid' }
        run_test!
      end

      response '401', 'Invalid credentials' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end
  end

  path '/apps/name_suggestion' do
    get 'Retrieve a suggested descriptive name for a new app' do
      tags 'Apps'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'application/json'

      response '200', 'New name suggestion' do
        schema type: :object, properties: {
          suggestion: {type: :string}
        },
        required: ['suggestion']
        run_test!
      end

      response '401', 'Invalid credentials' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end
  end

end
