require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe 'factory' do
    it 'is valid' do
      organization = FactoryBot.create(:organization)
      expect(organization).to be_valid
    end
  end

  describe 'associations' do
    it 'creates an organization with users and roles' do
      organization = FactoryBot.create(:organization, members_count: 2)

      # Ensure the organization is valid
      expect(organization).to be_valid

      # Verify the number of users and roles
      expect(organization.users.count).to eq(3)
      expect(OrgRole.where(organization: organization, role: 'member').count).to eq(2)
      expect(OrgRole.where(organization: organization, role: 'admin').count).to eq(1)
    end
  end
end
