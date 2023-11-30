require 'swagger_helper'

describe 'Invitations API' do

  let(:user) { FactoryBot.create(:user, :logged_in, role: :admin) }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:client) { user.tokens.keys.first }
  let(:expiry) { user.tokens[client]['expiry'] }
  let(:uid) { user.uid }

  before do
    @admin = user
    @organization = FactoryBot.create(:organization, admin: @admin)
  end

  path '/auth/invitation' do
    post 'invite new user' do
      tags 'Invitations'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :invite, in: :body, schema: { 
        type: :object,
        properties: { 
          email: { type: :string },
          invitation_metadata: { 
            type: :object,
            properties: { 
              org_id: { type: :integer },
              role: { type: :string }
            },
            required: %w( org_id role )
          }
        },
        required: %w( email org_role )
      }

      let(:email) { 'fake@email.com' }

      let(:org_id) { @organization.id }
      let(:role){ 'member' }
      let(:invitation_metadata) { { org_id: org_id, role: role } }
      
      let(:invite) { { email: email, invitation_metadata: invitation_metadata } }

      response '201', 'Invite New User' do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(User.count).to eq(2)
        end
      end
    end
  end
end
