require 'rails_helper'

RSpec.describe Chart, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe 'validations' do
    let(:chart) { FactoryBot.build :chart }
    before do
      chart.dashboard.save!
      chart.register.save!
    end

    context 'name' do
      it 'is required' do
        chart.name = nil
        expect(chart).not_to be_valid
        expect(chart.errors[:name]).to include("can't be blank")
      end

      it 'is unique within the scope of dashboard and register' do
        FactoryBot.create(:chart, name: 'Revenue', dashboard: chart.dashboard, register: chart.register)
        chart.name = 'Revenue'
        expect(chart).not_to be_valid
        expect(chart.errors[:name]).to include('Revenue already exists as a chart name for this dashboard and register')
      end
    end

    context 'chart_type' do
      it 'is required' do
        chart.chart_type = nil
        expect(chart).not_to be_valid
        expect(chart.errors[:chart_type]).to include("can't be blank")
      end
    end

    context 'color_scheme' do
      it 'is required' do
        chart.color_scheme = nil
        expect(chart).not_to be_valid
        expect(chart.errors[:color_scheme]).to include("can't be blank")
      end
    end

    context 'report_period' do
      it 'is required' do
        chart.report_period = nil
        expect(chart).not_to be_valid
        expect(chart.errors[:report_period]).to include("can't be blank")
      end

      it 'must be one of the valid periods' do
        chart.report_period = 'invalid_period'
        expect(chart).not_to be_valid
        expect(chart.errors[:report_period]).to include('invalid_period is not a valid report period')
      end
    end

    context 'default_time_range' do
      it 'is required' do
        chart.default_time_range = ''
        expect(chart).not_to be_valid
        expect(chart.errors[:default_time_range]).to be_present
      end

      it 'accepts static time ranges' do
        static_ranges = %w[today yesterday last_week last_month last_year ytd]
        static_ranges.each do |range|
          chart.default_time_range = range
          expect(chart).to be_valid
        end
      end

      it 'accepts properly formatted last_n_days ranges' do
        dynamic_ranges = %w[last_7_days last_30_days last_90_days last_365_days last_123456789_days]
        dynamic_ranges.each do |range|
          chart.default_time_range = range
          expect(chart).to be_valid
        end
      end

      it 'rejects invalid time ranges' do
        invalid_ranges = %w[last_-1_days last_0_days last_007_days invalid]
        invalid_ranges.each do |range|
          chart.default_time_range = range
          expect(chart).not_to be_valid
          expect(chart.errors[:default_time_range]).to be_present
        end
      end
    end

    context 'default_timezones' do
      it 'is required' do
        chart.default_timezones = nil
        expect(chart).not_to be_valid
        expect(chart.errors[:default_timezones]).to include("can't be blank")
      end

      it 'must contain only valid time zones' do
        chart.default_timezones = ['Invalid/Zone']
        expect(chart).not_to be_valid
        expect(chart.errors[:default_timezones]).to include('Invalid/Zone is not a valid time zone')
      end

      it 'is valid with only valid time zones' do
        chart.default_timezones = ['UTC', 'America/New_York']
        expect(chart).to be_valid
      end
    end
  end

  describe 'instance methods' do
    let(:chart) { FactoryBot.create :chart }

    describe '#aliased_groups' do
      it 'produces an aliased report_groups hash' do
        expect(chart.aliased_groups).to eq({
          'customer_id' => false,
          'income_account' => false,
          'entity_type' => false,
          'entity_id' => false
        })
      end
    end

    describe '#unaliased_groups' do
      it 'can produce an unaliased report_groups hash' do
        expect(chart.unaliased_groups).to eq({
          'meta0' => false,
          'meta1' => false,
          'meta2' => false,
          'meta3' => false
        })
      end
    end

    describe '#unalias_groups!' do
      it 'de-aliases a valid report_groups hash' do
        report_groups = {
          'income_account' => false,
          'customer_id' => true
        }
        unaliased_groups = chart.unalias_groups!(report_groups)
        expect(unaliased_groups).to eq({ 'meta1' => false, 'meta0' => true })
      end

      it 'raises an error for invalid report_groups' do
        report_groups = {
          'not_a_real_label' => false
        }
        expect do
          chart.unalias_groups!(report_groups)
        end.to raise_error(StandardError)
      end
    end

    describe '#default_timezone' do
      it 'returns the first timezone in the array of default timezones' do
        expect(chart.default_timezone).to eq('America/New_York')
      end
    end

    describe '#time_range_bounds' do
      before do
        chart.update!(default_timezones: %w[America/New_York UTC Asia/Tokyo])
      end

      around do |example|
        travel_to Time.zone.local(2024, 1, 15, 4, 0, 0) do
          example.run
        end
      end

      context 'with invalid timezone' do
        it 'raises ArgumentError' do
          expect {
            chart.time_range_bounds(timezone: 'Invalid/Zone')
          }.to raise_error(ArgumentError, /Invalid timezone/)
        end
      end

      context 'with valid timezone' do
        shared_examples 'returns correct time bounds' do |timezone, expected_offset|
          it "returns correct bounds for #{timezone}" do
            result = chart.time_range_bounds(timezone: timezone)

            expect(result[:start_at]).to be_a(String)
            expect(result[:end_at]).to be_a(String)
            expect(result[:start_at].to_time.utc_offset).to eq(expected_offset)
            expect(result[:end_at].to_time.utc_offset).to eq(expected_offset)
          end
        end

        it_behaves_like 'returns correct time bounds', 'UTC', 0
        it_behaves_like 'returns correct time bounds', 'America/New_York', -5 * 60 * 60 # -5 hours in seconds
        it_behaves_like 'returns correct time bounds', 'Asia/Tokyo', 9 * 60 * 60 # 9 hours in seconds
      end

      context 'with last_n_days time range' do
        [7, 30, 90].each do |days|
          context "with last_#{days}_days" do
            before { allow(chart).to receive(:default_time_range).and_return("last_#{days}_days") }

            it "returns correct bounds for last #{days} days" do
              result = chart.time_range_bounds

              expect(result[:start_at]).to eq((Time.current.in_time_zone(chart.default_timezone).beginning_of_day - days.days).iso8601)
              expect(result[:end_at]).to eq(Time.current.in_time_zone(chart.default_timezone).yesterday.end_of_day.iso8601)
            end

            it "maintains correct day count across timezones" do
              ['UTC', 'America/New_York', 'Asia/Tokyo'].each do |zone|
                result = chart.time_range_bounds(timezone: zone)
                day_count = (result[:start_at].to_date..result[:end_at].to_date).to_a.size

                expect(day_count).to eq(days)
              end
            end
          end
        end
      end
    end
  end
end
