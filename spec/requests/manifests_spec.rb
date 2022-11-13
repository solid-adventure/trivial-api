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

  def self.manifest_definition_schema
    {
      type: :object,
      properties: {
        app_id: { type: :string },
        content: { type: :object }
      },
      required: ['app_id', 'content']
    }
  end

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

        response '401', 'Invalid credentials' do
          let('access-token') { 'invalid-token' }
          run_test!
        end

      end

    end

    post('create manifest') do

      parameter name: :manifest, in: :body, schema: manifest_definition_schema
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      produces 'application/json'

      response(200, 'successful') do

        run_test! do |response|
          byebug
        end
      end
    end
  end

  # path '/manifests/{id}' do
  #   # You'll want to customize the parameter types...
  #   parameter name: 'id', in: :path, type: :string, description: 'id'

  #   get('show manifest') do
  #     response(200, 'successful') do
  #       let(:id) { '123' }

  #       after do |example|
  #         example.metadata[:response][:content] = {
  #           'application/json' => {
  #             example: JSON.parse(response.body, symbolize_names: true)
  #           }
  #         }
  #       end
  #       run_test!
  #     end
  #   end

    # patch('update manifest') do
    #   response(200, 'successful') do
    #     let(:id) { '123' }

    #     after do |example|
    #       example.metadata[:response][:content] = {
    #         'application/json' => {
    #           example: JSON.parse(response.body, symbolize_names: true)
    #         }
    #       }
    #     end
    #     run_test!
    #   end
    # end

    # put('update manifest') do
    #   response(200, 'successful') do
    #     let(:id) { '123' }

    #     after do |example|
    #       example.metadata[:response][:content] = {
    #         'application/json' => {
    #           example: JSON.parse(response.body, symbolize_names: true)
    #         }
    #       }
    #     end
    #     run_test!
    #   end
    # end

    # delete('delete manifest') do
    #   response(200, 'successful') do
    #     let(:id) { '123' }

    #     after do |example|
    #       example.metadata[:response][:content] = {
    #         'application/json' => {
    #           example: JSON.parse(response.body, symbolize_names: true)
    #         }
    #       }
    #     end
    #     run_test!
    #   end
    # end
  end
end
