require 'rails_helper'

describe Ownable do
  let(:user1) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }
  let(:user3) { FactoryBot.create(:user) }
  let(:organization1) { FactoryBot.create(:organization, admin: user1, members_count: 2) }
  let(:organization2) { FactoryBot.create(:organization, admin: user2, members_count: 2) }
  let(:ownable) { FactoryBot.create(:app, custom_owner: old_owner) }

  describe '#transfer_ownership' do
    describe "previous permissions" do
      let(:old_owner) { organization1 }
      let(:new_owner) { user3 }
      
      before(:example) do
        admins = organization2.org_roles.where(role: 'admin').pluck(:user_id)
        members = organization2.org_roles.where(role: 'member').pluck(:user_id)

        ownable.grant_all(user_ids: admins)
        ownable.grant(user_ids: members, permit: :read)

        @permitted_users = organization1.org_roles.pluck(:user_id) + organization2.org_roles.pluck(:user_id)
        @previous_permissions = Permission.where(permissible: ownable, user_id: @permitted_users)
      end
      
      context 'with revoke' do
        let(:revoke) { true }

        it 'revokes all previous permissions' do
          expect {
            ownable.transfer_ownership(new_owner: new_owner, revoke: revoke)
          }.to change(@previous_permissions, :count).to(0)
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
      end

      context 'transfer ownership to an Organization' do
        let(:new_owner) { organization2 }

        it 'correctly transfers ownership' do
          expect {
            ownable.transfer_ownership(new_owner: new_owner, revoke: revoke)
          }.to change(ownable, :owner).to(new_owner)
        end
      end
    end
  end

  describe '#admin?' do
    context 'resource owner is User' do
      before do
        @owner = FactoryBot.create(:user)
        @ownable = FactoryBot.create(:app, custom_owner: @owner)
      end

      it 'returns true if user is owner' do
        expect(@ownable.admin?(@owner)).to eq true
      end
      it 'returns false if user is not owner' do
        @other = FactoryBot.create(:user)
        expect(@ownable.admin?(@other)).to eq false
      end
    end
    context 'resource owner is Organization' do
      before do
        @org = FactoryBot.create(:organization, members_count: 1)
        @ownable = FactoryBot.create(:app, custom_owner: @org)
      end

      it 'returns true if user is admin of org' do
        admin = @org.users.find_by(org_roles: { role: 'admin' })
        expect(@ownable.admin?(admin)).to eq true
      end
      it 'returns false if user is member of org' do
        member = @org.users.find_by(org_roles: { role: 'member' })
        expect(@ownable.admin?(member)).to eq false
      end
      it 'returns false if user is not part of org' do
        other = FactoryBot.create(:user)
        expect(@ownable.admin?(other)).to eq false
      end
    end
  end
end
