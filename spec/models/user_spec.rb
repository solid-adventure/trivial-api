require 'rails_helper'

describe User do
  let(:user) { FactoryBot.create(:user) }
  let(:other) { FactoryBot.create(:user) }
  let(:org) { FactoryBot.create(:organization, admin: user, members_count: 1) }

  describe '#associated_apps' do
    let(:user_app) { FactoryBot.create(:app, owner: user) }
    let(:org_app) { FactoryBot.create(:app, owner: org) }
    let(:permitted_app) { FactoryBot.create(:app) }
    let!(:unrelated_app) { FactoryBot.create(:app) }
  
    it 'returns an empty collection if the user has no associated apps' do
      expect(user.associated_apps).to be_empty
    end
    
    it 'returns permitted resources if they exist' do
      permitted_app.grant_all(user_ids: user.id)
      expect(user.associated_apps).to contain_exactly(permitted_app)
    end
    
    it 'returns owned resources if they exist' do
      user_app
      expect(user.associated_apps).to contain_exactly(user_app)
    end
    
    it 'returns org associated apps if they exist' do
      org_app
      expect(user.associated_apps).to contain_exactly(org_app)
    end
    
    it 'returns all types of associated apps if they exist' do
      user_app
      org_app
      permitted_app.grant_all(user_ids: user.id)

      expect(user.associated_apps).to contain_exactly(user_app, org_app, permitted_app)
    end
  end

    describe '#associated_credential_sets' do
    let(:user_credential) { FactoryBot.create(:credential_set, owner: user) }
    let(:org_credential) { FactoryBot.create(:credential_set, owner: org) }
    let(:permitted_credential) { FactoryBot.create(:credential_set) }
    let!(:unrelated_credential) { FactoryBot.create(:credential_set) }
  
    it 'returns an empty collection if the user has no associated credentials' do
      expect(user.associated_credential_sets).to be_empty
    end
    
    it 'returns permitted resources if they exist' do
      permitted_credential.grant_all(user_ids: user.id)
      expect(user.associated_credential_sets).to contain_exactly(permitted_credential)
    end
    
    it 'returns owned resources if they exist' do
      user_credential
      expect(user.associated_credential_sets).to contain_exactly(user_credential)
    end
    
    it 'returns org associated credential_sets if they exist' do
      org_credential
      expect(user.associated_credential_sets).to contain_exactly(org_credential)
    end
    
    it 'returns all types of associated credential_sets if they exist' do
      user_credential
      org_credential
      permitted_credential.grant_all(user_ids: user.id)

      expect(user.associated_credential_sets).to contain_exactly(user_credential, org_credential, permitted_credential)
    end
  end

end
