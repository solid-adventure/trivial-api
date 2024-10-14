require 'rails_helper'

RSpec.describe StatsCacheWarmUpJob, type: :job do
  let(:app1) { FactoryBot.create :app }
  let(:app2) { FactoryBot.create :app }

  let(:date_cutoff) { Date.today - 7.days }
  let(:app_ids) { [app1.id, app2.id] }

  before do
    allow(App).to receive(:pluck).and_return(app_ids)
    allow(App).to receive(:cache_stats_for!)
  end

  describe '.perform' do
    it 'logs an error if app_ids is not an array' do
      expect(Rails.logger).to receive(:error).with("StatsCacheWarmUpJob failed: app_ids must be an array of integers")
      described_class.perform_now(app_ids: "not_an_array", date_cutoff:)
    end

    it 'logs an error if date_cutoff is not a Date' do
      expect(Rails.logger).to receive(:error).with("StatsCacheWarmUpJob failed: date_cutoff must be a Date type")
      described_class.perform_now(app_ids:, date_cutoff: "not_a_date")
    end
  end

  describe 'default parameters' do
    it 'uses default parameters if none are provided' do
      expect_any_instance_of(StatsCacheWarmUpJob).to receive(:sleep).and_return(0)
      expect(App).to receive(:cache_stats_for!).with(app_ids:, date_cutoff:)
      described_class.perform_now
    end
  end
end
