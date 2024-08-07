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
        dashboards: {
          type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string }
            },
            required: %w[ id name ]
          }
        },
        users: {
          type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              email: { type: :string },
              roles: { type: :string }
            },
            required: %w[ id name email roles ]
          }
        }
      },
      required: %w[ id name billing_email dashboards ]
    }
  end

  before do
    @admin = user
    @member = FactoryBot.create(:user)
    @test_org = FactoryBot.create(:organization, admin: FactoryBot.create(:user))
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

      response '200', 'User has no associated Organizations' do
        schema type: :array, items: organization_schema
        before do
          OrgRole.where(user: @admin).delete_all
        end
        run_test!
      end

      response '401', 'Invalid credentials' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end

    post 'create organization' do
      tags 'Organizations'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :organization, in: :body, schema: {
        type: :object,
        properties: { 
          name: { type: :string },
          billing_email: { type: :string }
        },
        required: [ 'name', 'billing_email' ]
      }

      let(:name) { 'New Organization' }
      let(:billing_email) { 'org@example.com' }
      let(:organization) { { name: name, billing_email: billing_email } }

      response '201', 'Create Organization' do
        schema type: :organization_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['name']).to eq(name)
          expect(data['billing_email']).to eq(billing_email)

          # Check if the organization is associated with the current user
          organization = Organization.find(data['id'])
          expect(@admin.reload.organizations).to include(organization)

          # Check if the user has an 'admin' OrgRole with the created Organization
          expect(organization.org_roles.find_by(user: @admin).role).to eq('admin')
        end
      end

      response '422', 'Missing or invalid field' do
        let(:name) { '' }
        run_test!
      end

      response '401', 'Invalid credentials' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end
  end

  path '/organizations/{id}' do
    parameter name: 'id', in: :path, type: :integer
    let(:id) { @orgs.first.id }

    get 'show organization' do
      tags 'Organizations'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'organization/json'

      before do
        OrgRole.create(user: @member, organization: @orgs.first, role: 'member')
      end

      response '200', 'Show Organization' do
        schema type: :organization_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['name']).to eq(@orgs.first.name)
          users = data['users']
          expect(users.count).to eq(2)
          expect(users[1]['name']).to eq(@member.name)
          expect(users[1]['email']).to eq(@member.email)
          expect(users[1]['role']).to eq('member')
        end
      end

      response '404', 'No Organization Found' do
        let(:id) { Organization.last.id + 999 }
        run_test!
      end

      response '401', 'User missing permissions' do
        let(:id) { @test_org.id }
        run_test!
      end

      response '401', 'Invalid credentials' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end

    put 'update organization' do
      tags 'Organizations'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      produces 'organization/json'

      parameter name: :organization, in: :body, schema: {
        type: :object,
        properties: { 
          name: { type: :string },
          billing_email: { type: :string }
        }
      }

      let(:name) { 'Updated Organization Name' }
      let(:organization) { { name: name } }

      response '200', 'Update Organization' do
        schema type: :organization_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['name']).to eq(name)
        end
      end

      response '404', 'No Organization Found' do
        let(:id) { Organization.last.id + 999 }
        run_test!
      end

      response '401', 'User missing permissions, no role' do
        let(:id) { @test_org.id }
        run_test!
      end

      response '401', 'User missing permissions, not admin' do
        before do
          OrgRole
            .find_by(user: @admin, organization: @orgs.first)
            .update_column(:role, 'member')
        end
        run_test!
      end

      response '401', 'Invalid credentials' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end

    delete 'destroy organization' do
      tags 'Organizations'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]

      response '204', 'No Content' do
        run_test! do
          expect(@admin.reload.organizations.count).to eq(@orgs.size - 1)
        end
      end

      response '404', 'No Organization Found' do
        let(:id) { Organization.last.id + 999 }
        run_test!
      end

      response '401', 'User missing permissions, no role' do
        let(:id) { @test_org.id }
        run_test!
      end

      response '401', 'User missing permissions, not admin' do
        before do
          OrgRole
            .find_by(user: @admin, organization: @orgs.first)
            .update_column(:role, 'member')
        end
        run_test!
      end

      response '401', 'Invalid credentials' do
        let('access-token') { 'invalid-token' }
        run_test!
      end
    end
  end

  path '/organizations/{id}/delete_org_role' do
    parameter name: 'id', in: :path, type: :integer
    let(:id) { @orgs.first.id }

    delete 'Delete Organization Role' do
      tags 'Organizations'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      consumes 'application/json'
      produces 'organization/json'

      parameter name: :organization, in: :body, schema: {
        type: :object,
        properties: {
          user_id: { type: :integer },
        }
      }
      before do
        OrgRole.create(user: @member, organization: @orgs.first, role: 'member')
      end

      let(:user_id) { @member.id }
      let(:organization) { { user_id: user_id } }

      response '204', 'Organization Role deleted' do
        run_test! do
          expect(@orgs.first.reload.org_roles.count).to eq(1)
        end
      end

      response '404', 'No Organization Found' do
        let(:id) { Organization.last.id + 999 }
        run_test!
      end

      response '404', 'No User Found' do
        let(:user_id) { User.last.id + 999 }
        run_test!
      end

      response '404', 'No OrgRole Found' do
        before do
          @member.org_roles.delete_all
        end
        run_test!
      end

      response '401', 'User missing permissions, no role' do
        before do
          @admin.org_roles.delete_all
        end
        run_test!
      end

      response '401', 'User missing permissions, not admin' do
        before do
          OrgRole
            .find_by(user: @admin, organization: @orgs.first)
            .update_column(:role, 'member')
        end
        run_test!
      end
    end
  end
end
