require 'rails_helper'

describe Organization do
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

  describe 'admin?' do
    before do
      @admin = FactoryBot.create :user
      @organization = FactoryBot.create :organization, admin: @admin, members_count: 1
      @member = @organization.org_roles.find_by(role: 'member').user
      @nonmember = FactoryBot.create :user
    end
    it 'is true if user is an admin of the Organization' do
      expect(@organization.admin?(@admin)).to be true
    end
    it 'is false if user is a member of the Organization' do
      expect(@organization.admin?(@member)).to be false
    end
    it 'is falsey for non-members of the Organization' do
      expect(@organization.admin?(@nonmember)).to be_falsey
    end
  end

  context 'customer_tags' do
    let(:customer_id) { '420' }

    describe 'find_by_customer_id' do
      before do
        @organization = FactoryBot.create :organization
        @organization.addTag!(:customer_id, customer_id)
      end

      it 'retrieves an organization tagged with a given customer_id' do
        expect(Organization.find_by_customer_id(customer_id)).to eq(@organization)
      end
    end

    describe 'create_by_customer_id' do
      it 'creates and tags an organization with a given customer_id' do
        organization = Organization.create_by_customer_id(customer_id)

        expect(organization).to be_persisted
        expect(organization.tags.count).to eq(1)

        customer_tag = organization.tags.first
        expect(customer_tag.name).to eq(customer_id)
        expect(customer_tag.context).to eq('customer_id')
      end
    end
  end
end
