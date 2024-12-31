
require 'rails_helper'
require 'swagger_helper'

describe "Charts API", type: :request do
  let(:user) { FactoryBot.create(:user, :logged_in) }
  let(:client) { user.tokens.keys.first }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:uid) { user.uid }
  let(:organization) { FactoryBot.create :organization, admin: user }
  let(:other_register) { organization.owned_registers.first }
  let(:current_register) { FactoryBot.create :register, owner: organization }
  let!(:register_item) { FactoryBot.create(:register_item, register: current_register, originated_at: Time.now) }

  def self.sum_schema
    {
      type: :object,
      properties: {
        sum: { type: :number }
      },
      required: %w[sum]
    }
  end

  def self.register_item_schema
     {
       type: :object,
       properties: {
         id: { type: :integer },
         register_id: { type: :integer },
         owner_type: { type: :string },
         owner_id: { type: :integer },
         unique_key: { type: :string },
         description: { type: :string },
         amount: { type: :string },
         units: { type: :string },
         invoice_id: { type: :integer },
         originated_at: { type: :string },
         created_at: { type: :string }
       },
       required: %w[id register_id owner_type owner_id unique_key description amount units invoice_id originated_at created_at]
     }
  end

  def self.register_item_body_schema
    {
      type: :object,
      properties: {
        public_app_id: { type: :integer },
        unique_key: { type: :string },
        description: { type: :string },
        register_id: { type: :integer },
        amount: { type: :number },
        units: { type: :string },
        originated_at: { type: :string }
      }
    }
  end

  before do
    FactoryBot.create(:register_item, register: current_register, originated_at: Time.now - 2.weeks)
    FactoryBot.create(:register_item, register: current_register, originated_at: Time.now - 1.week)
    FactoryBot.create(:register_item, register: other_register, originated_at: Time.now)
  end

  path '/register_items/sum' do
    parameter name: 'register_id', in: :query, type: :integer, description: 'A specific register id', required: false
    parameter name: 'col', in: :query, type: :integer, description: 'The column to sum on', required: false
    parameter name: 'search', in: :query, type: :string, description: 'A hash of filters', required: false

    get "Sum of RegisterItems" do
      tags 'RegisterItems'
      security [ { access_token: [], client: [], uid: [] } ]
      produces  'register_item/json'

      response '200', 'Get a sum of register_items, no filters' do
        schema type: sum_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['sum'].to_f).to eq(10.00)
        end
      end

      response '200', 'Get a sum of register_items, filtered on register' do
        schema type: sum_schema

        let(:register_id) { current_register.id }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['sum'].to_f).to eq(7.50)
        end
      end

      response '400', "injection attempt on sum column" do
        let(:col) { 'DROP TABLE users' }
        run_test!
      end
    end
  end

  path '/register_items/{register_item_id}' do
    parameter name: 'register_item_id', in: :path, type: :integer
    parameter name: 'register_id', in: :query, type: :integer
    let(:register_id) { current_register.id }
    let(:register_item_id) { register_item.id }

    put 'Update a RegisterItem' do
      tags 'RegisterItem'
      security [ { access_token: [], client: [], uid: [] } ]
      consumes 'application/json'
      produces 'register_item/json'

      parameter name: 'register_item_update', in: :body, schema: register_item_body_schema
      let(:register_item_update) {
        {
          amount: 2.17
        }
      }
      response '200', 'Update RegisterItem' do
        schema type: register_item_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['amount']).to eq("2.17")
        end
      end

      response '403', 'Update an Invoiced RegisterItem' do
        schema type: register_item_schema

        before do
          register_item.invoice = FactoryBot.create :invoice, owner: organization
          register_item.save!
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('RegisterItem is in a locked state')
        end
      end
    end
  end
end
