require 'rails_helper'

describe Permission do
  let(:user) { FactoryBot.create(:user) }
  let(:permissible) { FactoryBot.create(:app) }

  describe 'grant' do
    context 'with valid input' do
      it 'creates a new permission' do
        expect {
          Permission.grant(permissible: permissible, user_id: user.id, permit: :read)
        }.to change(Permission, :count).by(1)
      end

      it 'sets the correct permit value' do
        Permission.grant(permissible: permissible, user_id: user.id, permit: :read)
        permission = Permission.last
        expect(permission.permit).to eq(Permission::PERMISSIONS_HASH[:read])
      end
    end

    context 'with invalid input' do
      it 'does not create a new permission' do
        expect {
          Permission.grant(permissible: permissible, user_id: user.id, permit: :invalid_permission)
        }.not_to change(Permission, :count)
      end
    end
  end

  describe 'grant_all' do
    it 'creates the full set of permissions for a specific permissible' do
      Permission.grant_all(permissible: permissible, user_id: user.id)

      expect(Permission.count).to eq(Permission::PERMISSIONS_HASH.length)

      Permission::PERMISSIONS_HASH.each do |_, bit|
        permission = Permission.find_by(permissible: permissible, user: user, permit: bit)
        expect(permission).to be_present
      end
    end
  end

  describe 'revoke' do
    before do
      Permission.create(user: user, permissible: permissible, permit: Permission::READ_BIT)
    end

    it 'revokes the specified permission for the given user and permissible' do
      expect {
        Permission.revoke(permissible: permissible, user_id: user.id, permit: :read)
      }.not_to change { Permission.count }

      expect(Permission.exists?(user: user, permissible: permissible, permit: Permission::READ_BIT)).to be false
      expect(Permission.exists?(user: user, permissible: permissible, permit: Permission::NO_PERMIT_BIT)).to be true
    end

    it 'revokes the specified permission for the given user and permissible with multiple permissions' do
      Permission.create(user: user, permissible: permissible, permit: Permission::UPDATE_BIT)

      expect {
        Permission.revoke(permissible: permissible, user_id: user.id, permit: :read)
      }.to change { Permission.count }.by(-1)

      expect(Permission.exists?(user: user, permissible: permissible, permit: Permission::NO_PERMIT_BIT)).to be false
      expect(Permission.exists?(user: user, permissible: permissible, permit: Permission::READ_BIT)).to be false
      expect(Permission.exists?(user: user, permissible: permissible, permit: Permission::UPDATE_BIT)).to be true
    end

    it 'does nothing if no permissions match the criteria' do
      Permission.create(user: user, permissible: permissible, permit: Permission::UPDATE_BIT)

      expect {
        Permission.revoke(permissible: permissible, user_id: user.id, permit: :delete)
      }.not_to change { Permission.count }
      
      expect(Permission.exists?(user: user, permissible: permissible, permit: Permission::NO_PERMIT_BIT)).to be false
    end
  end

  describe 'revoke_all' do
    it 'revokes all permissions for the specified user and resource' do
      Permission.create(user: user, permissible: permissible, permit: Permission::READ_BIT)
      Permission.create(user: user, permissible: permissible, permit: Permission::UPDATE_BIT)
      Permission.create(user: user, permissible: permissible, permit: Permission::DELETE_BIT)

      expect {
        Permission.revoke_all(permissible: permissible, user_id: user.id)
      }.to change { Permission.count }.by(-2)

      expect(Permission.exists?(user: user, permissible: permissible, permit: Permission::READ_BIT)).to be false
      expect(Permission.exists?(user: user, permissible: permissible, permit: Permission::UPDATE_BIT)).to be false
      expect(Permission.exists?(user: user, permissible: permissible, permit: Permission::DELETE_BIT)).to be false
      expect(Permission.exists?(user: user, permissible: permissible, permit: Permission::NO_PERMIT_BIT)).to be true
    end
  end
end
