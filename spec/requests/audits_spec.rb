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
            type: audit_schema,
          }
        },
        required: %w[page total_pages audits]
      }
    }
  end

  def self.audit_schema
    {
      type: :object,
      properties: {
        id: { type: :integer },
        reference_id: { type: :integer },
        reference_type: { type: :string },
        reference_name: { type: :string },
        user_id: { type: :integer },
        user_name: { type: :string },
        user_email: { type: :string },
        action: { type: :string },
        audited_changes: {
          type: :object,
          properties: {
            attribute: { type: :string },
            patch: { type: :string },
            old_value: {
              oneOf: [
                { type: :string },
                { type: :integer },
                { type: :object },
                { type: :array }
              ]
            },
            new_value: {
              oneOf: [
                { type: :string },
                { type: :integer },
                { type: :object },
                { type: :array }
              ]
            }
          },
          required: %w[attribute patch]
        },
        version: { type: :integer },
        remote_address: { type: :string },
        created_at: { type: :string }
      },
      required: %w[id user_id user_name user_email reference_id reference_type reference_name action audited_changes created_at]
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
          expect(audits[0]['reference_type']).to eq(@associated_auditable.class.to_s)
          expect(audits[0]['reference_id']).to eq(@associated_auditable.id)
          expect(audits[0]['reference_name']).to eq(@auditable.name)
          expect(audits[0]['action']).to eq('create')
          expect(audits[1]['reference_type']).to eq(@auditable.class.to_s)
          expect(audits[1]['reference_id']).to eq(@auditable.id)
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
        schema type: :audit_schema

        run_test! do |response|
          data = JSON.parse response.body

          audit = data['audit']
          expect(audit['id']).to eq(@audit.id)
          expect(audit['reference_type']).to eq(@auditable.class.to_s)
          expect(audit['reference_id']).to eq(@auditable.id)
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
