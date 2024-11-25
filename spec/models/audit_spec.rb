require 'rails_helper'

RSpec.describe Audited::Audit do
  let(:user) { FactoryBot.create :user }
  let!(:organization) { FactoryBot.create :organization, admin: user }
  let(:register) { organization.owned_registers.first }
  let(:item) { FactoryBot.create :register_item, register: }

  describe 'audited models' do
    context 'audited owned_audits: true' do
      it 'saves the owner for directly owned resources' do
        expect(register.audited_options[:owned_audits]).to be true
        register.update!(meta: { meta0: 'income_account' })
        expect(register.audits.count).to eq(2)
        register.audits.each do |audit|
          expect(audit.owner).to eq(organization)
        end
      end

      it 'saves the parents owner for associated resources' do
        expect(item.audited_options[:owned_audits]).to be true
        expect(item.audited_options[:associated_with]).to eq(:register)
        item.update!(amount: 100)
        expect(item.audits.count).to eq(2)
        item.audits.each do |audit|
          expect(audit.owner).to eq(item.register.owner)
        end
      end
    end

    context 'has_owned_audits' do
      it 'has owned_audits association' do
        expect(organization.respond_to? :owned_audits).to be true
        expect(organization.owned_audits.count).to eq(3)
        item
        expect(organization.owned_audits.count).to eq(4)
      end
    end

    it 'has the all_audits instance methods' do
      expect(organization.respond_to? :all_audits).to be true
      # all_audits: create org, create org_role, create user, create register, create dashboard, create chart
      expect(organization.all_audits.count).to eq(6)
      item
      expect(organization.all_audits.count).to eq(7)
    end
  end
end
