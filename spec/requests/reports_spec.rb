require 'rails_helper'
require 'swagger_helper'

describe "Reports API", type: :request do
  let(:user) { FactoryBot.create(:user, :logged_in) }
  let(:client) { user.tokens.keys.first }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:uid) { user.uid }
  let(:organization) { FactoryBot.create :organization, admin: user }
  let!(:register) { organization.owned_registers.first }
  let!(:invoice) { FactoryBot.create(:invoice, owner: organization) }
  let!(:register_item) {
    FactoryBot.create(
      :register_item,
      register:,
      originated_at: start_at + 1.day
    )
  }
  let!(:invoiced_register_item) {
    FactoryBot.create(
      :register_item,
      register:,
      invoice:,
      originated_at: start_at + 3.days
    )
  }

  let(:report_params) {
    {
      start_at: start_at.iso8601,
      end_at: end_at.iso8601,
      register_id: register.id,
    }
  }
  let(:start_at) { Time.new(2022,1,1) }
  let(:end_at) { start_at + 2.years - 1.second }

  def self.report_schema
    {
      type: :object,
      properties: {
        title: { type: String },
        count: {
          type: :array,
          items: {
            type: :object,
            properties: {
              period: { type: String },
              group: { type: String },
              value: { type: Float }
            },
            required: %w[period group value]
          }
        }
      },
      required: %w[title count]
    }
  end

  def self.report_request_schema
    {
      type: :object,
      properties: {
        start_at: { type: String },
        end_at: { type: String },
        register_id: { type: Integer },
        group_by_period: { type: String },
        timezone: { type: String },
        group_by: {
          type: :array,
          items: { type: String }
        },
        search: {
          type: :array,
          items: { type: :object }
        },
      },
      required: %w[start_at end_at register_id]
    }
  end

  path 'reports/item_count' do
    post "count of items in register" do
      tags 'Reports'
      security [ { access_token: [], client: [], uid: [] } ]
      consumes 'application/json'
      produces  'report/json'

      parameter name: :report_params, in: :body, schema: report_request_schema

      response '200', 'Show Item Count' do
        schema type: report_schema
        run_test! do |response|
          data = JSON.parse(response.body)
          data['count'].first['value'] == 2
        end
      end

      response '200', 'Item Count with Search' do
        schema type: report_schema

        before do
          search_hash = {
            c: 'invoice_id',
            o: '',
            p: 'IS NULL'
          }
          report_params[:search] = [search_hash]
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          data['count'].first['value'] == 1
        end
      end
    end
  end

  path 'reports/item_average' do
    post "average item amounts for register" do
      tags 'Reports'
      security [ { access_token: [], client: [], uid: [] } ]
      consumes 'application/json'
      produces  'report/json'

      parameter name: :report_params, in: :body, schema: report_request_schema

      response '200', 'Show Items Average' do
        schema type: report_schema
        run_test!
      end
    end
  end

  path 'reports/item_sum' do
    post "sum of item amounts for register" do
      tags 'Reports'
      security [ { access_token: [], client: [], uid: [] } ]
      consumes 'application/json'
      produces  'report/json'

      parameter name: :report_params, in: :body, schema: report_request_schema

      response '200', 'Show Items Sum' do
        schema type: report_schema
        run_test!
      end
    end
  end

  path 'reports/delete' do
    post "invalid report_name" do
      tags 'Reports'
      security [ { access_token: [], client: [], uid: [] } ]
      consumes 'application/json'
      produces  'report/json'

      parameter name: :report_params, in: :body, schema: report_request_schema

      response '422', 'invalid report' do
        run_test!
      end
    end
  end
end
