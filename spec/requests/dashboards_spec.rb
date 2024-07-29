require 'rails_helper'
require 'swagger_helper'

describe "Charts API", type: :request do
  let(:user) { FactoryBot.create(:user, :logged_in) }
  let(:client) { user.tokens.keys.first }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:uid) { user.uid }
  let!(:organization) { FactoryBot.create :organization, admin: user }
  let(:dashboard) { organization.owned_dashboards.first }

  def self.dashboard_schema
    {
      type: :object,
      properties: {
        id: { type: :integer },
        owner_type: { type: :string },
        owner_id: { type: :integer },
        name: { type: :string },
        dashboard_type: { type: :string },
        charts: {
          type: :array,
          items: { '$ref' => '#/components/schemas/chart_schema' }
        }
      },
      required: %w[id owner_type owner_id name dashboard_type charts]
    }
  end

  def self.create_dashboard_schema
    {
      type: :object,
      properties: {
        owner_type: { type: :string },
        owner_id: { type: :integer },
        name: { type: :string },
        dashboard_type: { type: :string },
      },
      required: %w[owner_type owner_id name]
    }
  end

  def self.update_dashboard_schema
    {
      type: :object,
      properties: {
        name: { type: :string },
        dashboard_type: { type: :string },
      }
    }
  end

  path 'dashboards' do
    get 'index associated dashboards' do
      tags 'Dashboards'
      security [ { access_token: [], client: [], uid: [] } ]
      produces  'dashboard/json'

      response '200', 'Index Associated Dashboards' do
        schema type: :object,
          properties: {
            dashboards: {
              type: :array,
              items: dashboard_schema
            },
            required: %w[dashboards]
          }

        before do
          FactoryBot.create :dashboard, owner: organization
          FactoryBot.create :register, owner: organization
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['dashboards'].length).to eq(2)
          expect(data['dashboards'].first['charts'].length).to eq(2)
        end
      end
    end

    post 'create dashboard' do
      tags 'Dashboards'
      security [ { access_token: [], client: [], uid: [] } ]
      consumes 'application/json'
      produces  'dashboard/json'

      parameter name: :create_dashboard, in: :body, schema: create_dashboard_schema
      let(:create_dashboard) {
        {
          owner_type: 'Organization',
          owner_id: organization.id,
          name: name
        }
      }
      let(:name) { 'Test Dashboard' }

      response '201', 'Create Dashboard' do
        schema type: dashboard_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['dashboard']['name']).to eq(name)
        end
      end

      response '422', 'Invalid Dashboard Params' do
        let(:create_dashboard) {
          {
            owner_type: 'User',
            owner_id: user.id,
            name: 'Test Dashboard'
          }
        }
        run_test!
      end

      response '401', 'User Not Authorized to Create Dashboard' do
        before do
          role = OrgRole.find_by(user: user, organization: organization)
          role.role = 'member'
          role.save!
        end
        run_test!
      end
    end
  end

  path 'dashboards/{dashboard_id}' do
    parameter name: 'dashboard_id', in: :path, type: :integer
    let(:dashboard_id) { dashboard.id }

    get 'show dashboard' do
      tags 'Dashboards'
      security [ { access_token: [], client: [], uid: [] } ]
      produces  'dashboard/json'

      response '200', 'Show Dashboard' do
        schema type: dashboard_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['dashboard']['owner_type']).to eq(dashboard.owner_type)
          expect(data['dashboard']['owner_id']).to eq(dashboard.owner_id)
          expect(data['dashboard']['name']).to eq(dashboard.name)
          expect(data['dashboard']['dashboard_type']).to eq(dashboard.dashboard_type)
        end
      end

      response '401', 'User Not Authorized to Read Dashboard' do
        before do
          organization.org_roles.destroy_all
        end
        run_test!
      end
    end

    put 'update dashboard' do
      tags 'Dashboards'
      security [ { access_token: [], client: [], uid: [] } ]
      consumes 'application/json'
      produces 'dashboard/json'

      parameter name: :dashboard_update, in: :body, schema: update_dashboard_schema
      let(:dashboard_update) {
        {
          name: name
        }
      }
      let(:name) { 'Test Dashboard' }

      response '200', 'Update Dashboard' do
        schema type: dashboard_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['dashboard']['name']).to eq(name)
        end
      end

      response '422', 'Invalid Dashboard Params' do
        let!(:other_dashboard) { FactoryBot.create :dashboard, owner: organization }
        let(:name) { other_dashboard.name }
        run_test!
      end

      response '401', 'User Not Authorized to Update Dashboard' do
        before do
          role = OrgRole.find_by(user: user, organization: organization)
          role.role = 'member'
          role.save!
        end
        run_test!
      end
    end

    delete 'destroy dashboard' do
      tags 'Dashboards'
      security [ { access_token: [], client: [], uid: [] } ]
      produces  'dashboard/json'

      response '200', 'Destroy Dashboard' do
        before do
          dashboard.charts.destroy_all
        end
        run_test!
      end

      response '401', 'User Not Authorized to Destroy Dashboard' do
        before do
          role = OrgRole.find_by(user: user, organization: organization)
          role.role = 'member'
          role.save!
        end
        run_test!
      end
    end
  end
end
