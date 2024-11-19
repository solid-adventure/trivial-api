require 'swagger_helper'

describe 'Activity Entries API' do

  include_context 'app_proxy_requests'

  let(:user) { FactoryBot.create(:user, :logged_in, role: :admin) }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:client) { user.tokens.keys.first }
  let(:expiry) { user.tokens[client]['expiry'] }
  let(:uid) { user.uid }
  let!(:user_app) { FactoryBot.create(:app, owner: user) }

  def self.activity_schema
    {
      type: :object,
      properties: {
        id: { type: :integer },
        owner_id: { type: :integer },
        owner_type: { type: :string },
        app_id: { type: :string },
        register_item_id: { type: :integer, nullable: true },
        activity_type: { type: :string },
        status: { type: :string, nullable: true },
        source: { type: :string, nullable: true },
        duration_ms: { type: :integer, nullable: true },
        payload: { type: :object, nullable: true },
        diagnostics: { type: :object, nullable: true }
      }, required: ['app_id', 'activity_type']
    }
  end

# Add this inside the main describe 'Activity Entries API' do block
# alongside the existing /activity_entries path block

  path '/activity_entries/search' do
    post 'Search activity entries' do
      tags 'Activity'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :search_params, in: :body, schema: {
        type: :object,
        properties: {
          search: {
            type: :array,
            items: {
              type: :object,
              properties: {
                c: { type: :string, description: 'Column name' },
                o: { type: :string, description: 'Operator' },
                p: {
                  type: :array,
                  items: { type: :integer },
                  description: 'Parameters'
                }
              },
              required: ['c', 'o', 'p']
            }
          }
        },
        required: ['search']
      }

      # Test data setup
      let!(:activity_entry_1) { FactoryBot.create(:activity_entry, :request, owner: user, app: user_app) }
      let!(:activity_entry_2) { FactoryBot.create(:activity_entry, :build, owner: user, app: user_app) }
      let!(:activity_entry_3) { FactoryBot.create(:activity_entry, :request, owner: user, app: user_app) }

      let(:search_params) {
        {
          search: [{
            c: 'id',
            o: 'IN',
            p: [activity_entry_1.id, activity_entry_2.id]
          }]
        }
      }

      # Happy path test
      response '200', 'Activity entries found' do
        schema type: :array, items: activity_schema

        run_test! do |response|
          data = JSON.parse(response.body)

          # Test that only requested entries are returned
          expect(data.length).to eq 2
          returned_ids = data.map { |entry| entry['id'] }
          expect(returned_ids).to match_array([activity_entry_1.id, activity_entry_2.id])
          expect(returned_ids).not_to include(activity_entry_3.id)

          # Test that entries are ordered by id desc
          expect(returned_ids).to eq returned_ids.sort.reverse
        end
      end  # end of 200 response block

      # Test string-based search parameter
      context 'with string-based search parameter' do
        let(:search_params) {
          {
            search: JSON.generate([{
              c: 'id',
              o: 'IN',
              p: [activity_entry_1.id, activity_entry_2.id]
            }])
          }
        }

        response '200', 'Activity entries found with string-based search' do
          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data.length).to eq 2
            expect(data.map { |entry| entry['id'] }).to match_array([activity_entry_1.id, activity_entry_2.id])
          end
        end
      end  # end of string-based search context

      # Test invalid search
      context 'with invalid search parameter' do
        let(:search_params) { { search: [] } }

        response '422', 'Invalid search parameters' do
          run_test! do |response|
            expect(response.body).to include('search required')
          end
        end
      end  # end of invalid search context

    end  # end of post 'Search activity entries' block
  end  # end of path block

  path '/activity_entries' do
    get 'Retrieve the list of activity' do
      tags 'Activity'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'application/json'
      parameter name: 'app_id', in: :query, required: true
      parameter name: 'limit', in: :query, required: false

      let(:app_id) { user_app.name }
      let(:limit) { 10 }
      let!(:build_entry) { FactoryBot.create(:activity_entry, :build, owner: user, app: user_app) }
      let!(:request_entry) { FactoryBot.create(:activity_entry, :request, owner: user, app: user_app) }

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
      let(:new_activity) {
        {
          app_id: user_app.name,
          activity_type: 'request',
          source: 'localhost',
          payload: payload
        }
      }

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
