
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

  def self.sum_schema
    {
      type: :object,
      properties: {
        sum: { type: :number }
      },
      required: %w[sum]
    }
  end

  before do
    FactoryBot.create(:register_item, register: current_register, originated_at: Time.now - 2.weeks)
    FactoryBot.create(:register_item, register: current_register, originated_at: Time.now - 1.week)
    FactoryBot.create(:register_item, register: current_register, originated_at: Time.now)
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

      response '200', 'Get a sum of register_items, no filters' do
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
end
