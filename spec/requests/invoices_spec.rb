require 'rails_helper'
require 'swagger_helper'

describe "Invoices API", type: :request do
  let(:user) { FactoryBot.create(:user, :logged_in) }
  let(:client) { user.tokens.keys.first }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:uid) { user.uid }
  let(:organization) { FactoryBot.create :organization, admin: user }
  let!(:invoice) { 
    FactoryBot.create(
      :invoice,
      owner: organization,
      date: Time.new(2024, 1, 1, 12) # 12pm Jan 1, 2024
    )
  }
  let!(:other_invoice) {
    FactoryBot.create(
      :invoice,
      owner: organization,
      date: Time.new(2024, 3, 1, 12) # 12pm March 1, 2024
    )
  }
  let!(:another_invoice) { FactoryBot.create :invoice }

  path 'invoices' do
    get "list of Invoices" do
      tags 'Invoice'
      security [ { access_token: [], client: [], uid: [] } ]
      produces  'invoice/json'
      parameter name: :search, in: :query, type: :string, required: false

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
          expect(data['invoices'].length).to eq(2)
          expect(data['invoices'].first['id']).to eq(invoice.id)
          expect(data['invoices'].last['id']).to eq(other_invoice.id)
        end
      end

      response '200', 'Index Invoices with Search' do
        schema type: :object,
          properties: {
            invoice_items: {
              type: :array,
              items: { '$ref' => '#/components/schemas/invoice_schema' }
            },
            required: %w[invoices]
          }

        let(:raw_search) { [{ 'c' => 'date', 'o' => '>', 'p' => Time.new(2024, 2, 1, 12).iso8601 }].to_json }
        let(:search) { URI.encode_www_form([raw_search.to_s]) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['invoices'].length).to eq(1)
          expect(data['invoices'].first['id']).to eq(other_invoice.id)
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
          expect(data['invoice']['id']).to eq(invoice.id)
          expect(data['invoice']['owner_type']).to eq(invoice.owner_type)
          expect(data['invoice']['owner_id']).to eq(invoice.owner_id)
          expect(data['invoice']['payee_id']).to eq(invoice.payee.id)
          expect(data['invoice']['payee_name']).to eq(invoice.payee.name)
          expect(data['invoice']['payor_id']).to eq(invoice.payor.id)
          expect(data['invoice']['payor_name']).to eq(invoice.payor.name)
          expect(data['invoice']['date']).to eq(invoice.date.iso8601(3))
          expect(data['invoice']['notes']).to eq(invoice.notes)
          expect(data['invoice']['currency']).to eq(invoice.currency)
          expect(data['invoice']['total']).to eq(invoice.total.to_s)
          expect(data['invoice']['created_at']).to eq(invoice.created_at.iso8601(3))
          expect(data['invoice']['updated_at']).to eq(invoice.updated_at.iso8601(3))
          expect(data['invoice']['invoice_items'].size).to eq(2)
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
