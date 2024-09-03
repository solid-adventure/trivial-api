require 'rails_helper'
require 'swagger_helper'

describe "Audits API", type: :request do
  let(:user) { FactoryBot.create(:user, :logged_in) }
  let(:client) { user.tokens.keys.first }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:uid) { user.uid }
  let(:organization) { FactoryBot.create :organization, admin: user }
  let(:auditable_app) { FactoryBot.create :app, owner: organization }

  def self.index_audits_schema
    {
      type: :object, 
      properties: {
        page: { type: :integer },
        total_pages: { type: :integer },
        audits: {
          type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              auditable_id: { type: :integer },
              auditable_type: { type: :string },
              associated_id: { type: :integer },
              associated_type: { type: :string },
              user_id: { type: :integer },
              action: { type: :string },
              version: { type: :integer },
              remote_address: { type: :string },
              created_at: { type: :string }
            },
            required: %w[id auditable_id auditable_type associated_id associated_type user_id action version remote_address created_at]
          }
        },
        required: %w[page total_pages audits]
      }
    }
  end

  def self.show_audit_schema
    {
      type: :object,
      properties: {
        id: { type: :integer },
        auditable_id: { type: :integer },
        auditable_type: { type: :string },
        associated_id: { type: :integer },
        associated_type: { type: :string },
        user_id: { type: :integer },
        action: { type: :string },
        audited_changes: {
          type: :object,
          additionalProperties: {
            oneOf: []
          }
        },
        version: { type: :integer },
        remote_address: { type: :string },
        created_at: { type: :string }
      },
      required: %w[id auditable_id auditable_type associated_id associated_type user_id action audited_changes version remote_address created_at]
    }
  end

  before do
    @auditable = auditable_app
  end

  path '{auditable_type}/{auditable_id}/audits' do
    parameter name: 'auditable_type', in: :path, type: :string
    parameter name: 'auditable_id', in: :path, type: :integer

    let(:auditable_type) { @auditable.class.to_s.tableize }
    let(:auditable_id) { @auditable.id }

    get "list resource's audits" do
      tags 'Audits'
      security [ { access_token: [], client: [], uid: [] } ]
      produces 'audit/json'

      response '200', 'Index Resource Audits' do
        schema type: :index_audit_schema

        before do
          @associated_auditable = FactoryBot.create(:manifest, app: auditable_app)
        end

        run_test! do |response|
          data = JSON.parse response.body

          audits = data['audits']
          expect(audits.count).to eq(2)
          expect(audits[0]['auditable_type']).to eq(@associated_auditable.class.to_s)
          expect(audits[0]['auditable_id']).to eq(@associated_auditable.id)
          expect(audits[0]['associated_type']).to eq(@auditable.class.to_s)
          expect(audits[0]['associated_id']).to eq(@auditable.id)
          expect(audits[0]['action']).to eq('create')
          expect(audits[1]['auditable_type']).to eq(@auditable.class.to_s)
          expect(audits[1]['auditable_id']).to eq(@auditable.id)
          expect(audits[1]['action']).to eq('create')
        end
      end

      response '401', 'Unauthorized User' do
        before do
          @auditable = FactoryBot.create :app
        end

        run_test!
      end
    end
  end

  path '{auditable_type}/{auditable_id}/audits/{audit_id}' do
    parameter name: 'auditable_type', in: :path, type: :string
    parameter name: 'auditable_id', in: :path, type: :integer
    parameter name: 'audit_id', in: :path, type: :integer

    let(:auditable_type) { @auditable.class.to_s.tableize }
    let(:auditable_id) { @auditable.id }
    let(:audit_id) { @audit.id }

    before do
      @audit = @auditable.audits.first
    end

    get "show resource's audit" do
      tags 'Audits'
      security [ { access_token: [], client: [], uid: [] } ]
      produces 'audit/json'

      response '200', "show audit for resource" do
        schema type: :show_audit_schema

        run_test! do |response|
          data = JSON.parse response.body

          audit = data['audit']
          expect(audit['id']).to eq(@audit.id)
          expect(audit['auditable_type']).to eq(@auditable.class.to_s)
          expect(audit['auditable_id']).to eq(@auditable.id)
        end
      end

      response '401', 'unauthorized user for audit' do
        before do
          @auditable = FactoryBot.create :app
        end

        run_test!
      end

      response '401', "unauthorized to view another resource's audit" do
        before do
          @other_auditable = FactoryBot.create(:app, owner: organization)
          @audit = @other_auditable.audits.first
        end

        run_test!
      end
    end
  end
end
