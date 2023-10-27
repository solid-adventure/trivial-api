# spec/requests/permissions_spec.rb

require 'swagger_helper'

describe 'Permissions API' do
  
  let(:user) { FactoryBot.create(:user, :logged_in, role: :admin) }
  let('access-token') { user.tokens[client]['token_unhashed'] }
  let(:client) { user.tokens.keys.first }
  let(:expiry) { user.tokens[client]['expiry'] }
  let(:uid) { user.uid }

  def self.user_permission_schema
    {
      type: :object,
      properties: {
        user_id: { type: :integer },
        permissions: {
          type: :array,
          items: {
            type: :object,
            properties: {
              permissible_type: { type: :string },
              permissible_id: { type: :integer },
              permits: {
                type: :array,
                items: { type: :string }
              },
              ids: {
                type: :array,
                items: { type: :integer }
              }
            },
            required: %w(permissible_type permissible_id permits ids)
          }
        }
      },
      required: %w(user_id permissions)
    }
  end

  def self.resource_permission_schema
    {
      type: :object,
      properties: {
        permissible_type: { type: :string },
        permissible_id: { type: :integer },
        permissions: {
          type: :array,
          items: {
            type: :object,
            properties: {
              user_id: { type: :integer },
              permits: {
                type: :array,
                items: { type: :string }
              },
              ids: {
                type: :array,
                items: { type: :integer }
              }
            },
            required: %w(user_id permits ids)
          }
        }
      },
      required: %w(permissible_type permissible_id permissions)
    }
  end

  before do
    @owner = user
    @permissible = FactoryBot.create(:app, :permissible, custom_owner: @owner)
  end

  path '/permissions/users/{user_id}' do
    parameter name: 'user_id', in: :path, type: :integer
    
    let(:user_id) { user.id }

    get 'Retrieve permissions for a user' do
      tags 'Permissions'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'permission/json'

      response '200', 'Permissions retrieved successfully' do
        schema type: :user_permission_schema

        before do
          @permissible2 = FactoryBot.create(:app)
          @permissible2.grant(user_ids: @owner.id, permit: :read)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['user_id']).to eq(user_id)
          
          permissions = data['permissions']
          expect(permissions.length).to eq(2)
          
          expect(permissions.first['permissible_type']).to eq(@permissible.class.to_s)
          expect(permissions.first['permissible_id']).to eq(@permissible.id)

          expect(permissions.first['permits']).to eq(Permission::PERMISSIONS_HASH.keys.map(&:to_s))
          expect(permissions.last['permits']).to eq(['read'])
        end
      end

      response '404', 'User not found' do
        let(:user_id) { User.last.id + 999 }
        run_test!
      end
    end
  end

  path '/permissions/{permissible_type}/{permissible_id}' do
    parameter name: 'permissible_type', in: :path, type: :string
    parameter name: 'permissible_id', in: :path, type: :integer

    let(:permissible_type) { @permissible.class.to_s.tableize }
    let(:permissible_id) { @permissible.id }

    
    get 'Retrieve permissions associated with a resource' do
      tags 'Permissions'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'permission/json'

      response '200', 'Permissions retrieved successfully' do
        schema type: :resource_permission_schema

        before do  
          @permitted_user = FactoryBot.create(:user)
          @permissible.grant(user_ids: @permitted_user.id, permit: :read)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['permissible_type']).to eq(@permissible.class.to_s)
          expect(data['permissible_id']).to eq(@permissible.id)
          
          permissions = data['permissions']
          expect(permissions.length).to eq(2)

          expect(permissions.first['user_id']).to eq(user.id)
          expect(permissions.last['user_id']).to eq(@permitted_user.id)

          expect(permissions.first['permits']).to eq(Permission::PERMISSIONS_HASH.keys.map(&:to_s))
          expect(permissions.last['permits']).to eq(['read'])
        end
      end

      response '422', 'Permissible Type not found' do
        let(:permissible_type) { 'fake_types' }
        run_test!
      end
      
      response '404', 'Permissible ID not found' do
        let(:permissible_id) { @permissible.id + 999 }
        run_test!
      end
    end
  end

  path '/permission/{permit}/{permissible_type}/{permissible_id}/users/{user_id}' do
    parameter name: 'permit', in: :path, type: :string
    parameter name: 'permissible_type', in: :path, type: :string
    parameter name: 'permissible_id', in: :path, type: :integer
    parameter name: 'user_id', in: :path, type: :integer
    
    let(:permit) { 'update' }
    let(:permissible_type) { @permissible.class.to_s.tableize }
    let(:permissible_id) { @permissible.id }
    
    let!(:permitted_user) { FactoryBot.create(:user) }
    let(:user_id) { permitted_user.id }

    post 'Grant Permission to User' do
      tags 'Permissions'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'permission/json'

      response '200', 'Permission granted successfully' do
        schema type: :user_permission_schema

        before do
          @permissible.grant(user_ids: permitted_user.id, permit: :read)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['user_id']).to eq(user_id)

          permissions = data['permissions']
          expect(permissions.length).to eq(1)
          
          expect(permissions.first['permissible_type']).to eq(@permissible.class.to_s)
          expect(permissions.first['permissible_id']).to eq(@permissible.id)

          expect(permissions.first['permits']).to eq(['read', 'update'])
        end
      end
    end

    delete 'Revoke Permission from User' do
      tags 'Permissions'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]

      response '204', 'No Content' do
        before do
          @permissible.grant(user_ids: permitted_user.id, permit: :read)
          @permissible.grant(user_ids: permitted_user.id, permit: :update)
        end

        run_test! do
          permissions = Permission.where(user: permitted_user)
          expect(permissions.count).to eq(1)
          expect(permissions.first.permit).to eq(Permission::READ_BIT)
        end
      end
    end
  end

  path '/permissions/{permissible_type}/{permissible_id}/users/{user_id}' do
    parameter name: 'permissible_type', in: :path, type: :string
    parameter name: 'permissible_id', in: :path, type: :integer
    parameter name: 'user_id', in: :path, type: :integer
    
    let(:permissible_type) { @permissible.class.to_s.tableize }
    let(:permissible_id) { @permissible.id }
    
    let!(:permitted_user) { FactoryBot.create(:user) }
    let(:user_id) { permitted_user.id }

    post 'Grant All Permissions to User' do
      tags 'Permissions'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]
      produces 'permission/json'

      response '200', 'Permissions granted successfully' do
        schema type: :user_permission_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['user_id']).to eq(user_id)

          permissions = data['permissions']
          expect(permissions.length).to eq(1)

          expect(permissions.first['permissible_type']).to eq(@permissible.class.to_s)
          expect(permissions.first['permissible_id']).to eq(@permissible.id)

          expect(permissions.first['permits']).to eq(Permission::PERMISSIONS_HASH.keys.map(&:to_s))
        end
      end
    end

    delete 'Revoke All Permissions from User' do
      tags 'Permissions'
      security [ { access_token: [], client: [], uid: [], token_type: [] } ]

      response '204', 'No Content' do
        before do
          @permissible.grant(user_ids: permitted_user.id, permit: :read)
          @permissible.grant(user_ids: permitted_user.id, permit: :update)
        end

        run_test! do
          permissions = Permission.where(user: permitted_user)
          expect(permissions.count).to eq(1)
          expect(permissions.first.permit).to eq(Permission::NO_PERMIT_BIT)
        end
      end
    end
  end
end

