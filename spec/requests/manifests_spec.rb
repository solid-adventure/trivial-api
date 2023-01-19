require 'swagger_helper'

# describe 'Apps API' do
describe 'manifests', type: :request do

  let(:user) { FactoryBot.create(:user, :logged_in) }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:client) { user.tokens.keys.first }
  let(:expiry) { user.tokens[client]['expiry'] }
  let(:uid) { user.uid }

  let!(:user_app) { FactoryBot.create(:app, user: user ) }
  let!(:user_manifest) { FactoryBot.create(:manifest, user: user, app_id: user_app.name, internal_app_id: user_app.id) }

  path '/manifests?app_id={appId}' do
    get('list manifests') do

      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'application/json'
      parameter name: "appId", in: :path, type: :string

      response(200, 'successful') do
        let(:appId) { user_app.name }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq 1
          expect(data.first['id']).to eq user_manifest.id
        end
      end

      response '200', 'No manifests found with bad appId' do
        let(:appId) { 'invalid' }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["manifests"].length).to eq 0
        end
      end

      response '401', 'Invalid credentials' do
        let(:appId) { user_app.name }
        let('access-token') { 'invalid-token' }
        run_test!
      end

    end

    post('create manifest') do
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'application/json'
      consumes 'application/json'
      parameter name: "appId", in: :path, type: :string
      parameter name: :manifest, in: :body, schema: {}

      response(400, 'malformed with bad appId') do
        let(:appId) { 'invalid' }
        let(:manifest) { {content: '{}'} }
        run_test!
      end


      response(400, 'malformed without required fields') do
        let(:appId) { user_app.name }
        let(:manifest) { {} }
        run_test!
      end

      response(201, 'valid with required fields') do
        let(:appId) { user_app.name }
        let(:manifest) { {content: '{}'} }
        run_test!
      end


    end

  end

  path '/manifests/{id}' do

    get('show manifest') do
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'application/json'
      parameter name: 'id', in: :path, type: :string, description: 'id'

      response(200, 'successful') do
        let(:id) { user_manifest.id }
        run_test!
      end

      response(404, 'unsuccessful with bad id') do
        let(:id) { 123 }
        run_test!
      end

      response(401, 'unsuccessful with bad auth') do
        let(:id) { user_manifest.id }
        let('access-token') { 'invalid-token' }
        run_test!
      end
  
    end

    patch('update manifest') do
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'application/json'
      consumes 'application/json'
      parameter name: 'id', in: :path, type: :string, description: 'id'
      parameter name: :manifest, in: :body, schema: {}

      response(200, 'successful') do
        let(:id) { user_manifest.id }
        let(:manifest) { {content: '{updated: true}'} }

        run_test! do |response|
          content = JSON.parse(response.body)['content']
          expect(content).to eq '{updated: true}'
        end
      end

      response(401, 'unsuccessful with bad auth') do
        let(:id) { user_manifest.id }
        let(:manifest) { {content: '{updated: true}'} }
        let('access-token') { 'invalid-token' }
        run_test!
      end

    end

    put('update manifest') do
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'application/json'
      consumes 'application/json'
      parameter name: 'id', in: :path, type: :string, description: 'id'
      parameter name: :manifest, in: :body, schema: {}

      response(200, 'successful') do
        let(:id) { user_manifest.id }
        let(:manifest) { {content: '{updated2: true}'} }

        run_test! do |response|
          content = JSON.parse(response.body)['content']
          expect(content).to eq '{updated2: true}'
        end
      end

      response(401, 'unsuccessful with bad auth') do
        let(:id) { user_manifest.id }
        let(:manifest) { {content: '{updated: true}'} }
        let('access-token') { 'invalid-token' }
        run_test!
      end


    end


  end
end