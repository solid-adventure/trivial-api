require 'rails_helper'

describe Permission do
  let(:user) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }
  let(:user3) { FactoryBot.create(:user) }
  let!(:permissible) { FactoryBot.create(:app) }

  describe 'grant' do
    context 'with valid input' do
      it 'creates a new permission when none exist' do
        expect {
          permissible.grant(user_ids: user.id, permit: :read)
        }.to change(Permission, :count).by(1)

        permission = Permission.last
        expect(permission.permissible).to eq(permissible)
        expect(permission.user).to eq(user)
        expect(permission.permit).to eq(Permission::PERMISSIONS_HASH[:read])
      end

      it 'updates NO_PERMIT_BIT permission instead of creating a new one' do
        permission = Permission.create(permissible: permissible, user: user, permit: Permission::NO_PERMIT_BIT)

        expect {
          permissible.grant(user_ids: user.id, permit: :update)
        }.to_not change(Permission, :count)

        expect(permission.reload.permit).to eq(Permission::PERMISSIONS_HASH[:update])
      end

      it 'does not create a new permission when it was already granted' do
        Permission.create(permissible: permissible, user: user, permit: Permission::READ_BIT)

        expect {
          permissible.grant(user_ids: user.id, permit: :read)
        }.to_not change(Permission, :count)
      end

      it 'creates permissions for each user given multiple input' do
        users = [user.id, user2.id, user3.id]

        expect {
          permissible.grant(user_ids: users, permit: :grant)
        }.to change(Permission, :count).by(3)

        permits = Permission.where(permissible: permissible, user_id: users, permit: Permission::GRANT_BIT)
        expect(permits.count).to eq(3)
      end
    end

    context 'with invalid input' do
      it 'does not create a new permission for invalid permit types' do
        expect {
          permissible.grant(user_ids: user.id, permit: :invalid_permission)
        }.not_to change(Permission, :count)
      end
    end
  end

  describe 'revoke' do
    context 'on a single user' do
      before do
        @permission = Permission.create(permissible: permissible, user: user, permit: Permission::READ_BIT)
      end

      it 'changes the permission to NO_PERMIT_BIT when only one permit exists' do
        expect {
          permissible.revoke(user_ids: user.id, permit: :read)
        }.not_to change(Permission, :count)

        expect(@permission.reload.permit).to eq(Permission::NO_PERMIT_BIT)
      end

      it 'destroys the specified permission when multiple permissions exist for user and permissible pair' do
        Permission.create(permissible: permissible, user: user, permit: Permission::UPDATE_BIT)

        expect {
          permissible.revoke(user_ids: user.id, permit: :read)
        }.to change(Permission, :count).by(-1)

        expect(Permission.exists?(permissible: permissible, user: user, permit: Permission::NO_PERMIT_BIT)).to be false
        expect(Permission.exists?(permissible: permissible, user: user, permit: Permission::READ_BIT)).to be false
        expect(Permission.exists?(permissible: permissible, user: user, permit: Permission::UPDATE_BIT)).to be true
      end

      it 'does nothing if no permissions match the criteria' do
        Permission.create(permissible: permissible, user: user, permit: Permission::UPDATE_BIT)

        expect {
          permissible.revoke(user_ids: user.id, permit: :delete)
        }.not_to change(Permission, :count)
        
        expect(Permission.exists?(permissible: permissible, user: user, permit: Permission::NO_PERMIT_BIT)).to be false
      end
    end

    context 'on multiple users' do
      before do
        @user_ids = [user.id, user2.id, user3.id]
        @user_ids.each do |user_id|
          Permission.create(permissible: permissible, user_id: user_id, permit: Permission::READ_BIT)
        end
      end

      it 'revokes from each user' do
        expect {
          permissible.revoke(user_ids: @user_ids, permit: :read)
        }.not_to change(Permission, :count)

        revoked_permits = Permission.where(permissible: permissible, user_id: @user_ids, permit: Permission::NO_PERMIT_BIT)
        expect(revoked_permits.count).to eq(3)
      end

      it 'correctly deletes permissions' do
        @user_ids.each do |user_id|
          Permission.create(permissible: permissible, user_id: user_id, permit: Permission::UPDATE_BIT)
        end

        expect {
          permissible.revoke(user_ids: @user_ids, permit: :update)
        }.to change(Permission, :count).by(-3)

        expect(Permission.exists?(permissible: permissible, user_id: @user_ids, permit: Permission::NO_PERMIT_BIT)).to be false
      end
    end
  end

  describe 'grant_all' do
    context 'when no permissions exist' do
      it 'creates the full set of permissions for a specific permissible' do
        expect {
          permissible.grant_all(user_ids: user.id)
        }.to change(Permission, :count).by(Permission::PERMISSIONS_HASH.length)

        permissions = Permission.where(permissible: permissible, user_id: user.id)
        expect(permissions.count).to eq(Permission::PERMISSIONS_HASH.length)
        expect(permissions.pluck(:permit)).to contain_exactly(*Permission::PERMISSIONS_HASH.values)
      end
    end

    context 'when permission with NO_PERMIT_BIT exists' do
      before do
        Permission.create(permissible: permissible, user: user, permit: Permission::NO_PERMIT_BIT)
      end

      it 'deletes the existing permission and grants all permissions' do
        expect {
          permissible.grant_all(user_ids: user.id)
        }.to change(Permission, :count).by(Permission::PERMISSIONS_HASH.length - 1)

        permissions = Permission.where(permissible: permissible, user_id: user.id)
        expect(permissions.count).to eq(Permission::PERMISSIONS_HASH.length)
        expect(permissions.pluck(:permit)).to contain_exactly(*Permission::PERMISSIONS_HASH.values)
      end
    end

    context 'when some permissions already exist' do
      let!(:read_permit) { Permission.create(permissible: permissible, user: user, permit: Permission::READ_BIT) }
      let!(:update_permit) { Permission.create(permissible: permissible, user: user, permit: Permission::UPDATE_BIT) }

      it 'does not modify existing permissions and grants missing permissions' do
        expect {
          permissible.grant_all(user_ids: user.id)
        }.to change(Permission, :count).by(Permission::PERMISSIONS_HASH.length - 2)
        permissions = Permission.where(permissible: permissible, user_id: user.id)

        expect(permissions.count).to eq(Permission::PERMISSIONS_HASH.length)
        expect(permissions).to include(read_permit)
        expect(permissions).to include(update_permit)
        expect(permissions.pluck(:permit)).to contain_exactly(*Permission::PERMISSIONS_HASH.values)
      end
    end

    context 'on multiple users' do
      it 'grants all permits to each included user' do
        Permission.create(permissible: permissible, user: user, permit: Permission::READ_BIT)

        granted_user_ids = [user2.id, user3.id]
        expect { 
          permissible.grant_all(user_ids: granted_user_ids)
        }.to change(Permission, :count).by(Permission::PERMISSIONS_HASH.length * 2)

        expect(Permission.where(permissible: permissible, user: user).count).to eq(1)
        expect(Permission.where(permissible: permissible, user: user2).count).to eq(Permission::PERMISSIONS_HASH.length)
        expect(Permission.where(permissible: permissible, user: user3).count).to eq(Permission::PERMISSIONS_HASH.length)
      end
    end
  end

  describe 'revoke_all' do
    context 'when permissions exist' do
      before do
        Permission.create(permissible: permissible, user: user, permit: Permission::READ_BIT)
        Permission.create(permissible: permissible, user: user, permit: Permission::UPDATE_BIT)
        Permission.create(permissible: permissible, user: user, permit: Permission::DELETE_BIT)
      end
      
      it 'revokes all permissions and sets NO_PERMIT_BIT' do
        expect {
          permissible.revoke_all(user_ids: user.id)
        }.to change(Permission, :count).by(-2)

        permissions = Permission.where(permissible: permissible, user_id: user.id)
        expect(permissions.count).to eq(1)
        expect(permissions.first.permit).to eq(Permission::NO_PERMIT_BIT)
      end

      it 'does not delete permissions for other users' do
        @other_user = FactoryBot.create(:user)
        @permit = Permission.create(permissible: permissible, user: @other_user, permit: Permission::READ_BIT)
       
        expect {
          permissible.revoke_all(user_ids: user.id)
        }.not_to change(Permission.where(permissible: permissible, user: @other_user), :count)

        permissions = Permission.where(permissible: permissible, user_id: user.id)
        expect(permissions.count).to eq(1)
        expect(permissions.first.permit).to eq(Permission::NO_PERMIT_BIT)
        expect(@permit.reload.permit).to eq(Permission::READ_BIT)
      end

      it 'does not delete permissions for other permissibles' do        
        @other_permissible = FactoryBot.create(:app)
        @permit = Permission.create(permissible: @other_permissible, user: user, permit: Permission::READ_BIT)
       
        expect {
          permissible.revoke_all(user_ids: user.id)
        }.not_to change(Permission.where(permissible: @other_permissible, user: user), :count)

        permissions = Permission.where(permissible: permissible, user_id: user.id)
        expect(permissions.count).to eq(1)
        expect(permissions.first.permit).to eq(Permission::NO_PERMIT_BIT)
        expect(@permit.reload.permit).to eq(Permission::READ_BIT)
      end
    end

    context 'when no permissions exist' do
      it 'does not attempt any deletions' do
        expect(Permission).not_to receive(:delete_all)
        permissible.revoke_all(user_ids: user.id)
      end

      it 'does not set a NO_PERMIT_BIT' do
        permissible.revoke_all(user_ids: user.id)

        permissions = Permission.where(permissible: permissible, user: user)
        expect(permissions.count).to eq(0)
        expect(permissions.where(permit: Permission::NO_PERMIT_BIT).empty?).to be true
      end
    end

    context 'on multiple users' do
      before do
        @user_ids = [user.id, user2.id, user3.id]
        @user_ids.each do |user_id|
          Permission.create(permissible: permissible, user_id: user_id, permit: Permission::READ_BIT)
          Permission.create(permissible: permissible, user_id: user_id, permit: Permission::UPDATE_BIT)
          Permission.create(permissible: permissible, user_id: user_id, permit: Permission::DELETE_BIT)
        end
      end

      it 'deletes permits and sets NO_PERMIT_BIT for each user' do
        expect { 
          permissible.revoke_all(user_ids: @user_ids)
        }.to change(Permission.where(permissible: permissible, user_id: @user_ids), :count).to(3)

        revoked_permits = Permission.where(permissible: permissible, user_id: @user_ids)
        expect(revoked_permits.pluck(:permit)).to eq([Permission::NO_PERMIT_BIT, Permission::NO_PERMIT_BIT, Permission::NO_PERMIT_BIT])
      end
    end
  end
end
