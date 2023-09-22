# spec/controllers/organizations_controller_spec.rb

require 'rails_helper'

RSpec.describe OrganizationsController, type: :controller do
  # Include Devise test helpers for authentication
  include Devise::Test::ControllerHelpers

  let(:user) { FactoryBot.create(:user, :logged_in) } # Create a user

  describe 'POST #create' do
    it 'creates an organization and assigns admin role to the user' do
      # Define organization attributes as needed
      organization_attributes = {
        name: 'Test Organization',
        email: 'test@example.com'
      }

      # Set the user context to the signed-in user
      sign_in user

      # Post a request to create the organization
      post :create, params: { organization: organization_attributes }

      expect(Organization.count).to eq(1)
    end
  end
end
