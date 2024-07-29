require 'rails_helper'
require 'swagger_helper'

describe "Charts API", type: :request do
  let(:user) { FactoryBot.create(:user, :logged_in) }
  let(:client) { user.tokens.keys.first }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:uid) { user.uid }
  let(:organization) { FactoryBot.create :organization, admin: user, delete_callback_objects: true }
  let!(:dashboard) { FactoryBot.create :dashboard, owner: organization }
  let!(:register) { FactoryBot.create :register, owner: organization }
  let!(:chart) { register.charts.first }

  def self.create_chart_schema
    {
      type: :object,
      properties: {
        register_id: { type: :integer },
        name: { type: :string },
        chart_type: { type: :string },
        color_scheme: { type: :string },
        report_period: { type: :string },
        report_groups: {
          type: :object,
          additionalProperties: { type: :boolean }
        }
      },
      required: %w[dashboard_id register_id name report_period]
    }
  end

  def self.update_chart_schema
    {
      type: :object,
      properties: {
        register_id: { type: :integer },
        name: { type: :string },
        chart_type: { type: :string },
        color_scheme: { type: :string },
        report_period: { type: :string },
        report_groups: {
          type: :object,
          additionalProperties: { type: :boolean }
        }
      }
    }
  end

  path 'dashboards/{dashboard_id}/charts' do
    parameter name: 'dashboard_id', in: :path, type: :integer
    let(:dashboard_id) { dashboard.id }

    get "list dashboard's charts" do
      tags 'Charts'
      security [ { access_token: [], client: [], uid: [] } ]
      produces  'chart/json'

      response '200', 'Index Dashboard Charts' do
        schema type: :object,
          properties: {
            charts: {
              type: :array,
              items: { '$ref' => '#/components/schemas/chart_schema' }
            },
            required: %w[charts]
          }

        before do
          FactoryBot.create :chart, register: register, dashboard: dashboard
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['charts'].length).to eq(2)
          expect(data['charts'].first['report_groups'].length).to eq(4)
        end
      end

      response '401', "User Not Authorized to Read Dashboard's Charts" do
        before do
          organization.org_roles.destroy_all
        end
        run_test!
      end
    end

    post 'create chart for dashboard' do
      tags 'Charts'
      security [ { access_token: [], client: [], uid: [] } ]
      consumes 'application/json'
      produces  'chart/json'

      parameter name: :create_chart, in: :body, schema: create_chart_schema
      let(:create_chart) {
        {
          register_id: register.id,
          name: "Test Chart",
          chart_type: "test",
          color_scheme: "default",
          report_period: report_period,
          report_groups: {
            customer_id: false,
            income_account: true,
            entity_type: true,
            entity_id: true
          }
        }
      }
      let(:report_period) { 'year' }

      response '201', 'Create Dashboard Chart' do
        schema type: { '$ref' => '#/components/schemas/chart_schema' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['chart']['report_groups']['customer_id']).to be false
          expect(data['chart']['report_groups']['income_account']).to be true
          expect(data['chart']['report_groups']['entity_type']).to be true
          expect(data['chart']['report_groups']['entity_id']).to be true
        end
      end

      response '422', 'Invalid Chart Params' do
        let(:report_period) { 'millisecond' }
        run_test!
      end

      response '401', "User Not Authorized to Create Dashboard Chart" do
        before do
          role = OrgRole.find_by(user: user, organization: organization)
          role.role = 'member'
          role.save!
        end
        run_test!
      end
    end
  end

  path 'dashboards/{dashboard_id}/charts/{chart_id}' do
    parameter name: 'dashboard_id', in: :path, type: :integer
    parameter name: 'chart_id', in: :path, type: :integer
    let(:dashboard_id) { dashboard.id }
    let(:chart_id) { chart.id }

    get "show dashboard's chart" do
      tags 'Charts'
      security [ { access_token: [], client: [], uid: [] } ]
      produces  'chart/json'

      response '200', "Show Dashboard's Chart" do
        schema type: { '$ref' => '#/components/schemas/chart_schema' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data)
        end
      end

      response '404', 'Invalid Chart for Dashboard' do
        let(:chart) { FactoryBot.create :chart }
        run_test!
      end

      response '401', "User Not Authorized to Read Dashboard's Chart" do
        before do
          organization.org_roles.destroy_all
        end
        run_test!
      end
    end

    put "update dashboard's chart" do
      tags 'Charts'
      security [ { access_token: [], client: [], uid: [] } ]
      consumes 'application/json'
      produces  'chart/json'

      parameter name: :chart_update, in: :body, schema: update_chart_schema
      let(:chart_update) {
        {
          name: name
        }
      }
      let(:name) { 'Test Chart' }

      response '200', "Update Dashboard's Chart" do
        schema type: { '$ref' => '#/components/schemas/chart_schema' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['chart']['name']).to eq(name)
        end
      end

      response '422', 'Invalid Chart Params' do
        let(:name) { nil }
        run_test!
      end

      response '404', 'Invalid Chart for Dashboard' do
        let(:chart) { FactoryBot.create :chart }
        run_test!
      end

      response '401', "User Not Authorized to Update Dashboard's Chart" do
        before do
          role = OrgRole.find_by(user: user, organization: organization)
          role.role = 'member'
          role.save!
        end
        run_test!
      end
    end

    delete "destroy dashboard's chart" do
      tags 'Charts'
      security [ { access_token: [], client: [], uid: [] } ]
      produces  'chart/json'

      response '200', "Destroy Dashboard's Charts" do
        run_test!
      end

      response '404', 'Invalid Chart for Dashboard' do
        let(:chart) { FactoryBot.create :chart }
        run_test!
      end

      response '401', "User Not Authorized to Destroy Dashboard's Chart" do
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
