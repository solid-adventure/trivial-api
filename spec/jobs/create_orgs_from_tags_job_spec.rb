require 'rails_helper'

RSpec.describe CreateOrgsFromTagsJob, type: :job do
  subject(:job_instance) { described_class.new }

  let!(:apps) { FactoryBot.create_list(:app, 5) }

  before do
    apps.each_with_index do |app, index|
      app.addTag!(:customer_id, index)
    end
  end

  context 'when no customer_ids already have associated organizations' do
    it 'creates an organization for each unassociated customer_id' do
      expect(Tag.where(context: 'customer_id', taggable_type: 'App').count).to eq(5)
      expect(Organization.count).to eq(0)
      expect(Tag.where(context: 'customer_id', taggable_type: 'Organization').count).to eq(0)

      expect {
        job_instance.perform
      }.to change {
        Organization.count
      }.from(0).to(5)

      expect(Tag.where(context: 'customer_id', taggable_type: 'Organization').count).to eq(5)
    end
  end

  context 'when all customer_ids already have associated organizations' do
    before do
      apps.each_with_index do |_, index|
        Organization.create_by_customer_id(index)
      end
    end

    it 'does not create duplicate organizations' do
      expect(Organization.count).to eq(5)
      expect(Tag.where(context: 'customer_id', taggable_type: 'Organization').count).to eq(5)

      expect { job_instance.perform }.not_to change { Organization.count }

      expect(Tag.where(context: 'customer_id', taggable_type: 'Organization').count).to eq(5)
    end
  end
end

