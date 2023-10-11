require 'swagger_helper'

describe 'Activity Entries API' do

  include_context 'app_proxy_requests'

  let(:user) { FactoryBot.create(:user, :logged_in, role: :admin) }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:client) { user.tokens.keys.first }
  let(:expiry) { user.tokens[client]['expiry'] }
  let(:uid) { user.uid }
  let!(:user_app) { FactoryBot.create(:app, user: user, owner: user) }

  def self.activity_schema
    {
      type: :object,
      properties: {
        app_id: { type: :string },
        activity_type: { type: :string },
        status: { type: :string, nullable: true },
        source: { type: :string, nullable: true },
        duration_ms: { type: :integer, nullable: true },
        payload: { type: :object, nullable: true },
        diagnostics: { type: :object, nullable: true }
      }, required: ['app_id', 'activity_type']
    }
  end

  path '/activity_entries' do
    get 'Retrieve the list of activity' do
      tags 'Activity'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'application/json'
      parameter name: 'app_id', in: :query, required: true
      parameter name: 'limit', in: :query, required: false

      let(:app_id) { user_app.name }
      let(:limit) { 10 }
      let!(:build_entry) { FactoryBot.create(:activity_entry, :build, user: user, owner: user, app: user_app) }
      let!(:request_entry) { FactoryBot.create(:activity_entry, :request, user: user, owner: user, app: user_app) }

      response '200', 'Activity listing returned' do
        schema type: :array, items: activity_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq 2
          expect(data.map{|a| a['id']}.sort).to eq [build_entry.id, request_entry.id].sort
        end
      end
    end

    post 'Log new activity' do
      tags 'Activity'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :new_activity, in: :body, schema: {
        type: :object,
        properties: {
          app_id: { type: :string },
          activity_type: { type: :string },
          status: { type: :string, nullable: true },
          source: { type: :string },
          duration_ms: { type: :integer, nullable: true },
          payload: { type: :object, nullable: true },
          diagnostics: { type: :object, nullable: true }
        },
        required: [ 'app_id', 'activity_type' ]
      }
      let(:payload) { {"test_data" => "12345"} }
      let(:new_activity) { {
        app_id: user_app.name,
        activity_type: 'request',
        source: 'localhost',
        payload: payload
      } }

      response '201', 'Activity logged', save_request_example: :new_activity do
        schema activity_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['app_id']).to eq user_app.name
          expect(data['activity_type']).to eq 'request'
          expect(data['source']).to eq new_activity[:source]
          expect(data['payload']).to eq payload
        end
      end
    end
  end

end
