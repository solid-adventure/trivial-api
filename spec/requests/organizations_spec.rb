require 'swagger_helper'

describe 'Organizations API' do

  let(:user) { FactoryBot.create(:user, :logged_in, role: :admin) }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:client) { user.tokens.keys.first }
  let(:expiry) { user.tokens[client]['expiry'] }
  let(:uid) { user.uid }

  def self.organization_schema
    {
      type: :object,
      properties: {
        id: { type: :integer },
        name: { type: :string },
        billing_email: { type: :string },
        token: { type: :string },
      },
      required: %w(id name billing_email token)
    }
  end

  before do
    @admin = user
    @orgs = []
    3.times do
      @orgs.push(FactoryBot.create( :organization, admin: @admin ))
    end
  end
  path '/organizations' do
    get 'list the organizations' do
      tags 'Organizations'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'organization/json'

      response '200', 'Organization listing' do
        schema type: :array, items: organization_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq(3)
          expect(data[1]['name']).to eq(@orgs[1].name)
        end
      end

      response '401', 'Invalid credentials' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end
  end
end
