require 'rails_helper'

RSpec.describe CacheWarmUpJob, type: :job do
  let(:app1) { FactoryBot.create :app }
  let(:app2) { FactoryBot.create :app }
  let(:instance) { described_class.new }

  before do
    allow(App).to receive(:pluck).and_return([app1.id, app2.id])
    allow(App).to receive(:cache_stats_for!)
    allow(instance).to receive(:sleep).and_return(nil)
  end

  describe '#perform' do
    it 'calls the correct helper method' do
      expect(instance).to receive(:warm_up_app_activity_stats)
      instance.perform(cache_name: 'app_activity_stats')
    end

    it 'passes options to the helper method' do
      app_ids = [app1.id]
      date_cutoff = Date.today - 3.days
      options = { app_ids:, date_cutoff: }

      expect(instance).to receive(:warm_up_app_activity_stats).with(app_ids:, date_cutoff:)
      instance.perform(cache_name: 'app_activity_stats', options:)
    end
  end

  describe '#warm_up_app_activity_stats' do
    let(:cache_name) { 'app_activity_stats' }
    let(:date_cutoff) { Date.today - 7.days }
    let(:app_ids) { [app1.id, app2.id] }

    it 'uses default parameters if none are provided' do
      expect(App).to receive(:cache_stats_for!).with(app_ids:, date_cutoff:)
      instance.perform(cache_name:)
    end

    it 'logs an error if app_ids is not an array' do
      options = { app_ids: "not_an_array", date_cutoff: }
      expect {
        instance.perform(cache_name:, options:)
      }.to output("CacheWarmUpJob failed: app_ids for app_activity_stats must be an array of integers\n").to_stdout
    end

    it 'logs an error if date_cutoff is not a Date' do
      options = { app_ids: , date_cutoff: 'not_a_date' }
      expect {
        instance.perform(cache_name:, options:)
      }.to output("CacheWarmUpJob failed: date_cutoff for app_activity_stats must be a Date type\n").to_stdout
    end
  end
end
