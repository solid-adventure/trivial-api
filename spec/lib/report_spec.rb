# spec/lib/report_spec.rb

require 'rails_helper'
require 'services/report'

RSpec.describe Services::Report do
  let(:report) { Services::Report.new }
  let(:register) { FactoryBot.create :register }
  let(:owner) { register.owner }
  let(:meta) { register.meta.invert }
  # args = :start_at, :end_at, :register_id, :group_by_period, :timezone, group_by: []

  before do
  end

  describe 'simple_stat_lookup' do
    let(:start_at) { Time.new(2023, 1, 1, 0, 0, 0, '-04:00') } # Jan 1, 2023 12:00:00AM EDT
    let(:end_at) { start_at + 1.year - 1.second } # Dec 31, 2023 11:59:59PM EDT
    let(:register_id) { register.id }
    let(:args) { 
      {
        start_at: start_at.iso8601,
        end_at: end_at.iso8601,
        register_id:,
        user: owner
      }
    }
    let(:originated_at) { start_at + 1.month } # Feb 1, 2023 12:00:00AM EDT

    before do
      FactoryBot.create(:register_item, originated_at:)
      @ri1 = FactoryBot.create(:register_item, register:, originated_at:)
      @ri2 = FactoryBot.create(
        :register_item,
        register:,
        originated_at: start_at + 3.months + 1.hour # April 1, 2023 1:00:00AM EDT
      )
      FactoryBot.create(:register_item, register: FactoryBot.create(:register, owner:), originated_at:)
    end

    it 'only includes specified registers' do
      results = report.send(:simple_stat_lookup, 'count', args)
      expect(results[:count].first[:value]).to eq(2)
    end

    it 'only uses the cache if the entire period is before the cache cutoff' do
      expect(report).to receive(:cached_simple_stat_lookup).once
      report.send(:simple_stat_lookup, 'count', args)
    end

    it 'only uses the live query if the entire period is after the cache cutoff' do
      args[:start_at] = (Time.now - 1.day).iso8601
      args[:end_at] = Time.now.iso8601
      expect(report).to receive(:_simple_stat_lookup).once
      report.send(:simple_stat_lookup, 'count', args)
    end

    it 'splits date range into a live and a cached query' do
      args[:timezone] = 'Etc/GMT+4'
      args[:end_at] = Time.now.in_time_zone(args[:timezone]).iso8601

      start_time = args[:start_at]
      end_time = args[:end_at]
      cutoff = report.cache_cutoff(args[:timezone]).iso8601

      expect(report).to receive(:cached_simple_stat_lookup).once do |stat, options|
        expect(stat).to eq('count')
        expect(options[:start_at]).to eq(start_time)
        expect(options[:end_at]).to eq(cutoff)
      end

      expect(report).to receive(:_simple_stat_lookup).once do |stat, options|
        expect(stat).to eq('count')
        expect(options[:start_at]).to eq(cutoff)
        expect(options[:end_at]).to eq(end_time)
      end

      allow(report).to receive(:combine_results).and_return({})
      results = report.send(:simple_stat_lookup, 'count', args)
    end

    it 'makes use of the cache' do
      expect(Rails.cache).to receive(:fetch).with(
        report.send(:cache_key, 'count', args),
         {expires_in: 1.day}
      ).and_yield
      report.send(:cached_simple_stat_lookup, 'count', args)
    end

    it 'combines the results of a live and a cached query' do
      args[:end_at] = Time.now.iso8601
      initialResult = report.send(:simple_stat_lookup, 'count', args)
      expect(initialResult[:count].first[:value]).to eq(2)
      FactoryBot.create(
        :register_item,
        register:,
        originated_at: Time.now - 1.hour
      )
      updatedResult = report.send(:simple_stat_lookup, 'count', args)
      expect(updatedResult[:count].first[:value]).to eq(3)
    end

    it 'uses a compatible timezone when splitting the queries' do
      timezone = report.send(:validate_timezone!, 'Etc/GMT+5')
      start_at = (Time.now - 1.week).in_time_zone(timezone).iso8601
      cutoff = report.cache_cutoff(timezone).iso8601
      expect(report.send(:validate_time_range!, start_at, cutoff, timezone)).to eq([start_at, cutoff])
    end

    it 'combines results when live and cached query have returned the same groups' do
      cached_result = {
        title: 'Count by Entity Type',
        count: [
          { period: 'All', group: 'Order', value: 2 }
        ]
      }
      live_result = {
        title: 'Count by Entity Type',
        count: [
          { period: 'All', group: 'Order', value: 3 }
        ]
      }
      result = report.send(:combine_results, cached_result, live_result)
      expect(result[:title]).to eq('Count by Entity Type')
      expect(result[:count].length).to eq(1)
      expect(result[:count][0][:value]).to eq(5)
    end

    it 'combines results when live and cached query have returned different periods' do
      cached_result = {:title=>"Count by Month", :count=>[{:period=>"Jan 2023", :group=>"All", :value=>0}, {:period=>"Feb 2023", :group=>"All", :value=>1} ]}
      live_result =   {:title=>"Count by Month", :count=>[{:period=>"Mar 2023", :group=>"All", :value=>2}, {:period=>"Apr 2023", :group=>"All", :value=>3} ]}
      result = report.send(:combine_results, cached_result, live_result)
      result[:count].each_with_index do |group, i|
        expect(group[:value]).to eq(i)
      end
    end

    it 'combines results when live and cached query have returned overlapping groups' do
      cached_result = {:title=>"Count by Month", :count=>[{:period=>"Jan 2023", :group=>"All", :value=>0}, {:period=>"Feb 2023", :group=>"All", :value=>1} ]}
      live_result =   {:title=>"Count by Month", :count=>[{:period=>"Feb 2023", :group=>"All", :value=>2} ]}
      result = report.send(:combine_results, cached_result, live_result)
      expect(result[:count][0][:value]).to eq(0) # Jan 2023, 0
      expect(result[:count][1][:value]).to eq(3) # Feb 2023, 1 + 2
    end

    it 'combines results when live and cached query have multidimensional groups' do
      cached_result = {:title=>"Count by Entity Type, Entity Id", :count=>[{:period=>"All", :group=>["Order", "1"], :value=>0}, {:period=>"All", :group=>["Order", "2"], :value=>1}]}
      live_result =   {:title=>"Count by Entity Type, Entity Id", :count=>[{:period=>"All", :group=>["Order", "1"], :value=>2}, {:period=>"All", :group=>["Order", "3"], :value=>3}]}
      result = report.send(:combine_results, cached_result, live_result)
      expect(result[:count][0][:value]).to eq(2) # Order 1, 0 + 2
      expect(result[:count][1][:value]).to eq(1) # Order 2, 1
      expect(result[:count][2][:value]).to eq(3) # Order 3, 3
    end

     it 'combines results when live and cached query have multidimensional groups and different periods' do
      cached_result = {:title=>"Count by Quarter and Entity Type, Entity Id", :count=>[{:period=>"Q1 2023", :group=>["Order", "2"], :value=>0}, {:period=>"Q2 2023", :group=>["Order", "2"], :value=>1}]}
      live_result =   {:title=>"Count by Quarter and Entity Type, Entity Id", :count=>[{:period=>"Q3 2023", :group=>["Order", "3"], :value=>2}, {:period=>"Q3 2023", :group=>["Order", "4"], :value=>4}]}
      result = report.send(:combine_results, cached_result, live_result)
      expect(result[:count][0][:value]).to eq(0) # Q1 2023, Order 2, 0
      expect(result[:count][1][:value]).to eq(1) # Q2 2023, Order 2, 1
      expect(result[:count][2][:value]).to eq(2) # Q3 2023, Order 3, 2
      expect(result[:count][3][:value]).to eq(4) # Q3 2023, Order 4, 4
    end

    it 'produces a valid cache key' do
      key = report.send(:cache_key, 'count', args)
      expect(key).to eq("simple_stat_lookup/count_{:start_at=>\"2023-01-01T00:00:00-04:00\", :end_at=>\"2023-12-31T23:59:59-04:00\", :register_id=>#{args[:register_id]}}")
    end

    it 'only includes specified dates' do
      args[:end_at] = (start_at + 2.months - 1.second).iso8601 # Feb 28, 2023 11:59:59PM EDT
      results = report.send(:simple_stat_lookup, 'count', args)
      expect(results[:count].first[:value]).to eq(1)
    end

    it "does not invert amount's sign by default" do
      results = report.send(:simple_stat_lookup, 'sum', args)
      expect(results[:count].first[:value]).to eq(5.0)
    end

    it "inverts amount's sign when invert_sign is true" do
      args[:invert_sign] = true
      results = report.send(:simple_stat_lookup, 'sum', args)
      expect(results[:count].first[:value]).to eq(-5.0)
    end

    it "correctly inverts amount's sign when grouping" do
      args[:group_by] = ['income_account']
      results = report.send(:simple_stat_lookup, 'sum', args)
      expect(results[:count][0][:value]).to eq(2.5)
      expect(results[:count][1][:value]).to eq(2.5)

      args[:invert_sign] = true
      results = report.send(:simple_stat_lookup, 'sum', args)
      expect(results[:count][0][:value]).to eq(-2.5)
      expect(results[:count][1][:value]).to eq(-2.5)
    end

    it 'correctly groups results given a :group_by' do
      args[:group_by] = ['entity_type']
      results = report.send(:simple_stat_lookup, 'count', args)
      expect(results[:count].count).to eq(1)
      expect(results[:count][0][:value]).to eq(2)

      args[:group_by] = ['income_account']
      results = report.send(:simple_stat_lookup, 'count', args)
      expect(results[:count].count).to eq(2)
      results[:count].each do |group|
        expect(group[:value]).to eq(1)
      end
    end

    it 'correctly groups by time period' do
      args[:group_by_period] = 'month'
      args[:timezone] = 'Etc/GMT+4' # EDT
      results = report.send(:simple_stat_lookup, 'count', args)
      expect(results[:count].count).to eq(12)
      expect(results[:count][0][:value]).to eq(0) # January, 2023 EDT
      expect(results[:count][1][:value]).to eq(1) # February, 2023 EDT
      expect(results[:count][2][:value]).to eq(0) # March, 2023 EDT
      expect(results[:count][3][:value]).to eq(1) # April, 2023 EDT
      expect(results[:count][4][:value]).to eq(0) # May, 2023 EDT
    end

    it 'correctly accounts for timezones' do
      args[:start_at] = Time.new(2023, 1, 1, 0, 0, 0, '-05:00').iso8601 # Jan 1, 2023 12:00:00AM EST
      args[:end_at] = Time.new(2023, 12, 31, 23, 59, 59, '-05:00').iso8601 # Dec 31, 2023 11:59:59PM EST
      args[:group_by_period] = 'month'
      args[:timezone] = 'Etc/GMT+5' # EST
      results = report.send(:simple_stat_lookup, 'count', args)
      expect(results[:count].count).to eq(12)
      expect(results[:count][0][:value]).to eq(1) # January, 2023 EST
      expect(results[:count][1][:value]).to eq(0) # February, 2023 EST
      expect(results[:count][2][:value]).to eq(0) # March, 2023 EST
      expect(results[:count][3][:value]).to eq(1) # April, 2023 EST
      expect(results[:count][4][:value]).to eq(0) # May, 2023 EST
    end

    it 'formats grouping by column correctly' do
      args[:group_by] = ['entity_type']
      results = report.send(:simple_stat_lookup, 'count', args)
      expect(results[:title]).to eq('Count by Entity Type')
      expect(results[:count].length).to eq(1)
      expect(results[:count][0][:period]).to eq('All')
      expect(results[:count][0][:group]).to eq('Order')
      expect(results[:count][0][:value]).to eq(2)
    end

    it 'formats grouping by period correctly' do
      args[:group_by_period] = 'quarter'
      args[:timezone] = 'Etc/GMT+4' # EDT
      results = report.send(:simple_stat_lookup, 'count', args)
      expect(results[:title]).to eq('Count by Quarter')
      expect(results[:count].length).to eq(4)
      expect(results[:count][0][:period]).to eq('Q1 2023')
      expect(results[:count][0][:group]).to eq('All')
      expect(results[:count][0][:value]).to eq(1)
      expect(results[:count][1][:period]).to eq('Q2 2023')
      expect(results[:count][1][:group]).to eq('All')
      expect(results[:count][1][:value]).to eq(1)
      expect(results[:count][2][:period]).to eq('Q3 2023')
      expect(results[:count][2][:group]).to eq('All')
      expect(results[:count][2][:value]).to eq(0)
      expect(results[:count][3][:period]).to eq('Q4 2023')
      expect(results[:count][3][:group]).to eq('All')
      expect(results[:count][3][:value]).to eq(0)
    end

    it 'formats grouping by period and column correctly' do
      args[:group_by_period] = 'quarter'
      args[:timezone] = 'Etc/GMT+4' # EDT
      args[:group_by] = ['entity_type']
      results = report.send(:simple_stat_lookup, 'count', args)
      expect(results[:title]).to eq('Count by Quarter and Entity Type')
      expect(results[:count].length).to eq(4)
      expect(results[:count][0][:period]).to eq('Q1 2023')
      expect(results[:count][0][:group]).to eq('Order')
      expect(results[:count][0][:value]).to eq(1)
      expect(results[:count][1][:period]).to eq('Q2 2023')
      expect(results[:count][1][:group]).to eq('Order')
      expect(results[:count][1][:value]).to eq(1)
      expect(results[:count][2][:period]).to eq('Q3 2023')
      expect(results[:count][2][:group]).to eq('Order')
      expect(results[:count][2][:value]).to eq(0)
      expect(results[:count][3][:period]).to eq('Q4 2023')
      expect(results[:count][3][:group]).to eq('Order')
      expect(results[:count][3][:value]).to eq(0)
    end

    describe 'multidimensional group_by' do
      let(:r1_entity_data) { [ @ri1[meta['entity_type']], @ri1[meta['entity_id']] ] }
      let(:r2_entity_data) { [ @ri2[meta['entity_type']], @ri2[meta['entity_id']] ] }

      it 'formats correctly with no group_by period' do
        args[:group_by] = ['entity_type', 'entity_id']
        results = report.send(:simple_stat_lookup, 'count', args)
        expect(results[:title]).to eq('Count by Entity Type, Entity Id')
        expect(results[:count][0][:group]).to eq(r1_entity_data)
        expect(results[:count][1][:group]).to eq(r2_entity_data)
      end

      it 'formats correctly with group_by period' do
        args[:group_by] = ['entity_type', 'entity_id']
        args[:group_by_period] = 'quarter'
        args[:timezone] = 'Etc/GMT+4' # EDT
        results = report.send(:simple_stat_lookup, 'count', args)
        expect(results[:title]).to eq('Count by Quarter and Entity Type, Entity Id')
        expect(results[:count][0][:period]).to eq('Q1 2023')
        expect(results[:count][0][:group]).to eq(r1_entity_data)
        expect(results[:count][1][:period]).to eq('Q2 2023')
        expect(results[:count][1][:group]).to eq(r1_entity_data)
        expect(results[:count][2][:period]).to eq('Q3 2023')
        expect(results[:count][2][:group]).to eq(r1_entity_data)
        expect(results[:count][3][:period]).to eq('Q4 2023')
        expect(results[:count][3][:group]).to eq(r1_entity_data)
        expect(results[:count][4][:period]).to eq('Q1 2023')
        expect(results[:count][4][:group]).to eq(r2_entity_data)
        expect(results[:count][5][:period]).to eq('Q2 2023')
        expect(results[:count][5][:group]).to eq(r2_entity_data)
        expect(results[:count][6][:period]).to eq('Q3 2023')
        expect(results[:count][6][:group]).to eq(r2_entity_data)
        expect(results[:count][7][:period]).to eq('Q4 2023')
        expect(results[:count][7][:group]).to eq(r2_entity_data)
      end
    end

    it 'raises an error when no register_id is provided' do
      args.delete(:register_id)
      expect do
        report.send(:simple_stat_lookup, 'count', args)
      end.to raise_error(ArgumentError)
    end

    it 'raises an error when no start_at is provided' do
      args.delete(:start_at)
      expect do
        report.send(:simple_stat_lookup, 'count', args)
      end.to raise_error(ArgumentError)
    end

    it 'raises an error when no end_at is provided' do
      args.delete(:end_at)
      expect do
        report.send(:simple_stat_lookup, 'count', args)
      end.to raise_error(ArgumentError)
    end

    it 'raises an error if start_at >= end_at' do
      args[:start_at] = Time.new(2222, 1, 1, 0, 0, 0, '-04:00').iso8601 # Jan 1, 2222 12:00:00AM EDT
      expect do
        report.send(:simple_stat_lookup, 'count', args)
      end.to raise_error(ArgumentError)
    end

    it 'raises an error for invalid timezones' do
      args[:timezone] = 'Mars'
      expect do
        report.send(:simple_stat_lookup, 'count', args)
      end.to raise_error(ArgumentError)
    end

    it 'raises an error if start_at or end_at timezones mismatch from timezone' do
      args[:timezone] = 'Etc/GMT+5' # EST, start_at and end_at are EDT
      expect do
        report.send(:simple_stat_lookup, 'count', args)
      end.to raise_error(ArgumentError)
    end

    it 'raises an error when an invalid group_by is provided' do
      args[:group_by] = ['register_id']
      expect do
        report.send(:simple_stat_lookup, 'count', args)
      end.to raise_error(ArgumentError)
    end
  end
end
