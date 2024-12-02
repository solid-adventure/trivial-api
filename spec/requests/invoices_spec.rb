require 'rails_helper'
require 'swagger_helper'

describe "Invoices API", type: :request do
  let(:user) { FactoryBot.create(:user, :logged_in) }
  let(:client) { user.tokens.keys.first }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:uid) { user.uid }
  let(:organization) { FactoryBot.create :organization, admin: user }
  let!(:invoice) { FactoryBot.create :invoice, owner: organization }
  let!(:other_invoice) { FactoryBot.create :invoice }

  path 'invoices' do
    get "list of Invoices" do
      tags 'Invoice'
      security [ { access_token: [], client: [], uid: [] } ]
      produces  'invoice/json'

      response '200', "Index Invoices" do
        schema type: :object,
          properties: {
            invoice_items: {
              type: :array,
              items: { '$ref' => '#/components/schemas/invoice_schema' }
            },
            required: %w[invoices]
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['invoices'].length).to eq(1)
          expect(data['invoices'].first['id']).to eq(invoice.id)
        end
      end
    end
  end

  path 'invoices/{invoice_id}' do
    parameter name: 'invoice_id', in: :path, type: :integer
    let(:invoice_id) { invoice.id }

    get "show invoice" do
      tags 'Invoice'
      security [ { access_token: [], client: [], uid: [] } ]
      produces  'invoice/json'

      response '200', "Show Invoice" do
        schema type: { '$ref' => '#/components/schemas/invoice_schema' }

        run_test! do |response|
          data = JSON.parse(response.body)
        end
      end

      response '401', "User Not Authorized to Read Invoice" do
        before do
          organization.org_roles.destroy_all
        end
        run_test!
      end
    end
  end
end
