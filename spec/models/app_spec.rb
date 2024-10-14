require 'rails_helper'

RSpec.describe App, type: :model do
  let!(:app1) { FactoryBot.create :app }
  let!(:app2) { FactoryBot.create :app }
  let(:date1) { Date.new(2023, 1, 1) }
  let(:date2) { Date.new(2023, 1, 2) }
  let(:date3) { Date.new(2023, 1, 3) }
  let(:ok) { '200' }
  let(:failed) { '500' }
  let(:full_stats) {
    {
      app1.id => [
        { date: date1, count: { ok => 2, failed => 1 } },
        { date: date2, count: { ok => 1 } },
        { date: date3, count: {} }
      ],
      app2.id => [
        { date: date1, count: { ok => 1 } },
        { date: date2, count: { failed => 1 } },
        { date: date3, count: { ok => 1 } }
      ]
    }
  }

  before do
    FactoryBot.create(:activity_entry, app: app1, created_at: date1, status: ok)
    FactoryBot.create(:activity_entry, app: app1, created_at: date1, status: ok)
    FactoryBot.create(:activity_entry, app: app1, created_at: date1, status: failed)
    FactoryBot.create(:activity_entry, app: app1, created_at: date2, status: ok)
    FactoryBot.create(:activity_entry, app: app2, created_at: date1, status: ok)
    FactoryBot.create(:activity_entry, app: app2, created_at: date2, status: failed)
    FactoryBot.create(:activity_entry, app: app2, created_at: date3, status: ok)
  end

  describe '.format_activity' do
    let(:included_dates) { [date1, date2, date3] }
    let(:activity_groups) { ActivityEntry.group(:app_id, 'created_at::date', :status).count }

    it 'formats the activity data correctly' do
      result = described_class.format_activity(
        activity_groups:,
        app_ids: [app1.id, app2.id],
        included_dates:
      )

      expect(result).to eq(full_stats)
    end
  end

  describe '.activity_groups_for' do
    let(:time_range) { (date1.beginning_of_day)..(date3.end_of_day) }

    it 'returns correct activity groups for given app_ids and time range' do
      result = described_class.activity_groups_for(app_ids: [app1.id, app2.id], time_range: time_range)

      expect(result).to eq(
        {
          [app1.id, date1, ok] => 2,
          [app1.id, date1, failed] => 1,
          [app1.id, date2, ok] => 1,
          [app2.id, date1, ok] => 1,
          [app2.id, date2, failed] => 1,
          [app2.id, date3, ok] => 1
        }
      )
    end

    it 'filters by app_ids correctly' do
      result = described_class.activity_groups_for(app_ids: [app1.id], time_range: time_range)

      expect(result.keys.map(&:first).uniq).to eq([app1.id])
    end

    it 'filters by time_range correctly' do
      result = described_class.activity_groups_for(app_ids: [app1.id, app2.id], time_range: (date1.beginning_of_day)..(date2.end_of_day))

      expect(result.keys.map { |k| k[1] }.uniq).to match_array([date1, date2])
    end
  end

  describe '.stats_for' do
    let(:included_dates) { [date1, date2, date3] }
    let(:time_range) { (date1.beginning_of_day)..(date3.end_of_day) }

    it 'returns formatted stats for given app_ids, time_range, and included_dates' do
      result = described_class.stats_for(app_ids: [app1.id, app2.id], time_range:, included_dates:)

      expect(result).to eq(full_stats)
    end

    it 'includes all included_dates even if no activity' do
      extra_date = Date.new(2023, 1, 4)
      result = described_class.stats_for(
        app_ids: [app1.id, app2.id],
        time_range: (date1.beginning_of_day)..(extra_date.end_of_day),
        included_dates: included_dates + [extra_date]
      )

      expect(result[app1.id].last).to eq({ date: extra_date, count: {} })
      expect(result[app2.id].last).to eq({ date: extra_date, count: {} })
    end

    it 'includes all app_ids even if no activity' do
      extra_app = FactoryBot.create :app
      result = described_class.stats_for(app_ids: [app1.id, app2.id, extra_app.id], time_range:, included_dates:)

      expect(result[extra_app.id]).to match_array(
        [
          { date: date1, count: {} },
          { date: date2, count: {} },
          { date: date3, count: {} }
        ]
      )
    end

    it 'filters by app_ids correctly' do
      result = described_class.stats_for(app_ids: [app1.id], time_range: time_range, included_dates: included_dates)

      expect(result.keys).to eq([app1.id])
    end
  end

  describe '.cached_stats' do
    let(:date_cutoff) { date1 }

    it 'returns cached stats for given app_ids and date_cutoff' do
      allow(Rails.cache).to receive(:read)
        .and_return(nil)

      app1_cache_key = described_class.cache_key_for(app_id: app1.id, date_cutoff:)
      allow(Rails.cache).to receive(:read)
        .with(app1_cache_key)
        .and_return(full_stats[app1.id][0...-1])

      result = described_class.cached_stats(app_ids: [app1.id, app2.id], date_cutoff:)

      expect(result).to eq({ app1.id => full_stats[app1.id][0...-1] })
    end

    it 'returns an empty hash when no cached data is found' do
      allow(Rails.cache).to receive(:read).and_return(nil)

      result = described_class.cached_stats(app_ids: [app1.id, app2.id], date_cutoff:)

      expect(result).to eq({})
    end
  end

  describe '.cache_stats_for!' do
    let(:date_cutoff) { date1 }

    before do
      allow(Rails.cache).to receive(:write)
      described_class.instance_variable_set(:@cache_date_cutoff, date3)
    end

    it 'caches stats for given app_ids and date_cutoff' do
      allow(described_class).to receive(:stats_for).and_return(full_stats)

      described_class.cache_stats_for!(app_ids: [app1.id, app2.id], date_cutoff: date_cutoff)

      expect(described_class).to have_received(:stats_for).with(
        app_ids: [app1.id, app2.id],
        time_range: (date_cutoff.to_time..date3.to_time),
        included_dates: [date1, date2]
      )

      expect(Rails.cache).to have_received(:write).with(
        "app_activity_stats/#{app1.id}/#{date_cutoff}",
        full_stats[app1.id],
        expires_in: an_instance_of(Float)
      )

      expect(Rails.cache).to have_received(:write).with(
        "app_activity_stats/#{app2.id}/#{date_cutoff}",
        full_stats[app2.id],
        expires_in: an_instance_of(Float)
      )
    end

    it 'sets the correct expiration time' do
      allow(described_class).to receive(:stats_for).and_return({ app1.id => full_stats[app1.id] })
      time_now = Time.new(2023, 1, 1, 12, 0, 0) # Noon
      allow(Time).to receive(:now).and_return(time_now)

      described_class.cache_stats_for!(app_ids: [app1.id], date_cutoff: date_cutoff)

      expect(Rails.cache).to have_received(:write).with(
        "app_activity_stats/#{app1.id}/#{date_cutoff}",
        full_stats[app1.id],
        expires_in: (Time.now.end_of_day - time_now).seconds
      )
    end
  end

  describe '.uncached_stats_for' do
    let(:cache_date_cutoff) { date3 }
    let(:uncached_stats) {
      {
        app1.id => full_stats[app1.id][-1..],
        app2.id => full_stats[app2.id][-1..]
      }
    }

    before do
      described_class.instance_variable_set(:@cache_date_cutoff, cache_date_cutoff)
      allow(Date).to receive(:today).and_return(cache_date_cutoff)
    end

    it 'retrieves stats from after @cache_date_cutoff' do
      allow(described_class).to receive(:stats_for).and_return(uncached_stats)

      described_class.uncached_stats_for(app_ids: [app1.id, app2.id])

      expect(described_class).to have_received(:stats_for).with(
        app_ids: [app1.id, app2.id],
        time_range: (cache_date_cutoff.to_time..),
        included_dates: [cache_date_cutoff]
      )
    end
  end

  describe '.get_activity_stats_for' do
    let(:date_cutoff) { date1 }
    let(:cache_date_cutoff) { date3 }
    let(:app_names) { [app1.name, app2.name] }
    let(:uncached_stats) {
      {
        app1.id => full_stats[app1.id][-1..],
        app2.id => full_stats[app2.id][-1..]
      }
    }

    before do
      allow(described_class).to receive(:cached_stats).and_return({ app1.id => full_stats[app1.id][0...-1] })
      allow(described_class).to receive(:cache_stats_for!).and_return({ app2.id => full_stats[app2.id][0...-1] })
      allow(described_class).to receive(:uncached_stats_for).and_return(uncached_stats)
    end

    it 'gets cached and uncached stats' do
      described_class.get_activity_stats_for(app_names:, date_cutoff:)

      expect(described_class).to have_received(:cached_stats).with(
        app_ids: [app1.id, app2.id],
        date_cutoff:
      )

      expect(described_class).to have_received(:cache_stats_for!).with(
        app_ids: [app2.id],
        date_cutoff:
      )

      expect(described_class).to have_received(:uncached_stats_for).with(app_ids: [app1.id, app2.id])
    end

    it 'creates an array of hashes with app names and merged stats' do
      results = described_class.get_activity_stats_for(app_names:, date_cutoff:)
      expect(results).to eq(
        [
          { app_id: app1.name, stats: full_stats[app1.id] },
          { app_id: app2.name, stats: full_stats[app2.id] }
        ]
      )
    end
  end
end
