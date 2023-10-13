require 'rails_helper'

describe Permission do
  describe 'create_admin' do
    let(:user) { FactoryBot.create(:user) }
    let(:app) { FactoryBot.create(:app) }

    it 'creates the full set of permissions for a specific permissible' do
      byebug
      Permission.create_admin(permissible: app, user_id: user.id)

      expect(Permission.count).to eq(Permission::PERMISSIONS_HASH.length)

      Permission::PERMISSIONS_HASH.each do |_, bit|
        permission = Permission.find_by(permissible: app, user: user, permit: bit)
        expect(permission).to be_present
      end
    end
  end
end
