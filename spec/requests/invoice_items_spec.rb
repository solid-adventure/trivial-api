require 'rails_helper'
require 'swagger_helper'

describe "Invoice Items API", type: :request do
  let(:user) { FactoryBot.create(:user, :logged_in) }
  let(:client) { user.tokens.keys.first }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:uid) { user.uid }
  let(:organization) { FactoryBot.create :organization, admin: user }
  let(:invoice) { FactoryBot.create :invoice, owner: organization, invoice_items_count: 1 }
  let(:other_invoice) { FactoryBot.create :invoice, owner: organization }
  let(:invoice_item) { invoice.invoice_items.first }

  path 'invoices/{invoice_id}/invoice_items' do
    parameter name: 'invoice_id', in: :path, type: :integer
    let(:invoice_id) { invoice.id }

    get "list Invoice's Invoice Items" do
      tags 'Invoice Item'
      security [ { access_token: [], client: [], uid: [] } ]
      produces  'invoice_item/json'

      response '200', "Index Invoice's Invoice Items" do
        schema type: :object,
          properties: {
            invoice_items: {
              type: :array,
              items: { '$ref' => '#/components/schemas/invoice_item_schema' }
            },
            required: %w[invoice_items]
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['invoice_items'].length).to eq(1)
          expect(data['invoice_items'].first['id']).to eq(invoice_item.id)
        end
      end

      response '401', "User Not Authorized to Read Invoice's Invoice Items" do
        before do
          organization.org_roles.destroy_all
        end
        run_test!
      end
    end
  end

  path 'invoices/{invoice_id}/invoice_items/{invoice_item_id}' do
    parameter name: 'invoice_id', in: :path, type: :integer
    parameter name: 'invoice_item_id', in: :path, type: :integer
    let(:invoice_id) { invoice.id }
    let(:invoice_item_id) { invoice_item.id }

    get "show invoice's invoice_item" do
      tags 'Invoice Items'
      security [ { access_token: [], client: [], uid: [] } ]
      produces  'invoice_item/json'

      response '200', "Show Invoice's Invoice Item" do
        schema type: { '$ref' => '#/components/schemas/invoice_item_schema' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['invoice_item']['owner_type']).to eq(invoice.owner_type)
          expect(data['invoice_item']['owner_id']).to eq(invoice.owner_id)
          expect(data['invoice_item']['invoice_id']).to eq(invoice.id)
          expect(data['invoice_item']['income_account']).to eq(invoice_item.income_account)
          expect(data['invoice_item']['income_account_group']).to eq(invoice_item.income_account_group)
          expect(data['invoice_item']['quantity']).to eq(invoice_item.quantity.to_s)
          expect(data['invoice_item']['unit_price']).to eq(invoice_item.unit_price.to_s)
          expect(data['invoice_item']['extended_amount']).to eq(invoice_item.extended_amount.to_s)
          expect(data['invoice_item']['created_at']).to eq(invoice_item.created_at.iso8601(3))
          expect(data['invoice_item']['updated_at']).to eq(invoice_item.updated_at.iso8601(3))
        end
      end

      response '404', 'Invalid Invoice Item for Invoice' do
        let(:invoice_item) { FactoryBot.create :invoice_item }
        run_test!
      end

      response '401', "User Not Authorized to Read Invoice's Invoice Item" do
        before do
          organization.org_roles.destroy_all
        end
        run_test!
      end
    end
  end
end
