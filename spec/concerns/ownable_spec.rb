require 'rails_helper'

describe Ownable do
  let(:user1) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }
  let(:user3) { FactoryBot.create(:user) }
  let(:organization1) { FactoryBot.create(:organization, admin: user1, members_count: 2) }
  let(:organization2) { FactoryBot.create(:organization, admin: user2, members_count: 2) }
  let(:ownable) { FactoryBot.create(:app, :permissible, custom_owner: old_owner) }

  describe '#transfer_ownership' do
    describe "previous permissions" do
      let(:old_owner) { organization1 }
      let(:new_owner) { user3 }
      
      before(:example) do
        admins = organization2.org_roles.where(role: 'admin').pluck(:user_id)
        members = organization2.org_roles.where(role: 'member').pluck(:user_id)

        Permission.grant_all(permissible: ownable, user_ids: admins)
        Permission.grant(permissible: ownable, user_ids: members, permit: :read)

        @permitted_users = organization1.org_roles.pluck(:user_id) + organization2.org_roles.pluck(:user_id)
        @previous_permissions = Permission.where(permissible: ownable, user_id: @permitted_users)
      end
      
      context 'with revoke' do
        let(:revoke) { true }

        it 'revokes all previous permissions' do
          expect {
            ownable.transfer_ownership(new_owner: new_owner, revoke: revoke)
          }.to change(@previous_permissions, :count).to(@permitted_users.length)

          expect(@previous_permissions.distinct.pluck(:permit)).to eq([Permission::NO_PERMIT_BIT])
        end
      end

      context 'without revoke' do
        let(:revoke) { false }

        it 'does nothing to previous permissions' do
          expect {
            ownable.transfer_ownership(new_owner: new_owner, revoke: revoke)
          }.not_to change { @previous_permissions }
        end
      end
    end

    describe 'new owner' do
      let(:old_owner) { user1 }
      let(:revoke) { true }

      before(:example) do
      end

      context 'transfer ownership to a User' do
        let(:new_owner) { user2 }

        it 'correctly transfers ownership' do
          expect {
            ownable.transfer_ownership(new_owner: new_owner, revoke: revoke)
          }.to change(ownable, :owner).to(new_owner)
        end

        it 'grants the correct permissions to the new owner' do
          new_owner_permits = Permission.where(permissible: ownable, user_id: new_owner.id)
          expect(new_owner_permits.count).to eq(0)

          expect {
            ownable.transfer_ownership(new_owner: new_owner, revoke: revoke)
          }.to change(new_owner_permits, :count).to(Permission::PERMISSIONS_HASH.length)

          expect(new_owner_permits.pluck(:permit)).to eq(Permission::PERMISSIONS_HASH.values)
        end
      end

      context 'transfer ownership to an Organization' do
        let(:new_owner) { organization2 }

        it 'correctly transfers ownership' do
          expect {
            ownable.transfer_ownership(new_owner: new_owner, revoke: revoke)
          }.to change(ownable, :owner).to(new_owner)
        end

        it 'grants the correct permissions to the new owner' do
          admins = new_owner.org_roles.where(role: 'admin').pluck(:user_id)
          members = new_owner.org_roles.where(role: 'member').pluck(:user_id)
          admin_permits = Permission.where(permissible: ownable, user_id: admins)
          member_permits = Permission.where(permissible: ownable, user_id: members)

          expect(admin_permits.count).to eq(0)
          expect(member_permits.count).to eq(0)

          ownable.transfer_ownership(new_owner: new_owner, revoke: revoke)

          admin_permits.reload
          member_permits.reload
          expect(admin_permits.count).to eq(admins.length * Permission::PERMISSIONS_HASH.length)
          expect(member_permits.count).to eq(members.length)
          expect(admin_permits.pluck(:permit)).to eq((Permission::PERMISSIONS_HASH.values * admins.count).flatten)
          expect(member_permits.pluck(:permit)).to eq(([Permission::READ_BIT] * members.count).flatten)
        end
      end
    end
  end
end
