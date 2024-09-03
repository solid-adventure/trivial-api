require 'rails_helper'
require 'swagger_helper'

# describe 'Apps API' do
describe 'manifests', type: :request do

  let(:user) { FactoryBot.create(:user, :logged_in) }
  let(:client) { user.tokens.keys.first }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:uid) { user.uid }

  let!(:user_app) { FactoryBot.create(:app, owner: user ) }
  let!(:user_manifest) { FactoryBot.create(:manifest, custom_app: user_app) }

  def self.manifest_schema
    {
      type: :object,
      properties: {
        app_id: { type: :string },
        content: { type: :object }
      }
    }
  end

  path '/manifests?app_id={app_id}' do
    parameter name: 'app_id', in: :path, type: :string
    let(:app_id) { user_app.name }

    get 'list manifests' do
      tags 'Manifests'
      security [ { access_token: [], client: [], uid: [] } ]
      produces 'manifest/json'

      response '200', 'successful' do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq 1
          expect(data.first['id']).to eq user_manifest.id
        end
      end

      response '200', 'No manifests found with bad app_id' do
        let(:app_id) { 'invalid' }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq 0
        end
      end

      response '401', 'Invalid credentials' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end

    post 'create manifest' do
      tags 'Manifests'
      security [ { access_token: [], client: [], uid: [] } ]
      consumes 'application/json'
      produces 'manifest/json'

      parameter name: :manifest, in: :body, schema: manifest_schema

      response(401, 'unauthorized with bad app_id') do
        let(:app_id) { 'invalid' }
        let(:manifest) { { content: '{}' } }
        run_test!
      end

      response(400, 'malformed without required fields') do
        let(:manifest) { {} }
        run_test!
      end

      response(201, 'valid with required fields') do
        let(:manifest) { { content: '{}' } }
        run_test!
      end
    end
  end

  path '/manifests/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'id'
    let(:id) { user_manifest.id }

    get('show manifest') do
      security [ { access_token: [], client: [], uid: [] } ]
      produces 'application/json'

      response(200, 'successful') do
        run_test!
      end

      response(404, 'unsuccessful with bad id') do
        let(:id) { 123 }
        run_test!
      end

      response(401, 'unsuccessful with bad auth') do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end

    put('update manifest') do
      security [ { access_token: [], client: [], uid: [] } ]
      consumes 'application/json'
      produces 'manifest/json'

      parameter name: :manifest, in: :body, schema: manifest_schema

      response(200, 'successful') do
        let(:manifest) { { content: '{ updated2: true }' } }

        run_test! do |response|
          content = JSON.parse(response.body)['content']
          expect(content).to eq '{ updated2: true }'
        end
      end

      response(401, 'unsuccessful with bad auth') do
        let(:manifest) { { content: '{ updated: true }'} }
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end
  end
end
