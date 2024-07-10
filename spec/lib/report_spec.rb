# spec/lib/report_spec.rb

require 'rails_helper'
require 'services/report'

RSpec.describe Services::Report do
  let(:report) { Services::Report.new }
  let(:register) { FactoryBot.create :register }
  let(:owner) { register.owner }
  # args = :start_at, :end_at, :register_id, :group_by_period, :timezone, group_by: []

  before do
  end

  describe 'simple_stat_lookup' do
    let(:start_at) { Time.new(2023, 1, 1, 0, 0, 0, '-04:00') } # Jan 1, 2023 12:00:00AM EDT
    let(:end_at) { start_at + 1.year - 1.second } # Dec 31, 2023 11:59:59PM EDT
    let(:register_id) { register.id }
    let(:args) { 
      {
        start_at: start_at.to_s,
        end_at: end_at.to_s,
        register_id:,
        user: owner
      }
    }
    let(:originated_at) { start_at + 1.month } # Feb 1, 2023 12:00:00AM EDT

    before do
      FactoryBot.create(:register_item, originated_at:)
      FactoryBot.create(:register_item, register:, originated_at:)
      FactoryBot.create(
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

    it 'only includes specified dates' do
      args[:end_at] = (start_at + 2.months - 1.second).to_s # Feb 28, 2023 11:59:59PM EDT
      results = report.send(:simple_stat_lookup, 'count', args)
      expect(results[:count].first[:value]).to eq(1)
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
      args[:start_at] = Time.new(2023, 1, 1, 0, 0, 0, '-05:00').to_s # Jan 1, 2023 12:00:00AM EST
      args[:end_at] = Time.new(2023, 12, 31, 23, 59, 59, '-05:00').to_s # Dec 31, 2023 11:59:59PM EST
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

    it 'raises an error when no register_id is provided' do
      args.delete(:register_id)
      expect do
        report.send(:simple_stat_lookup, 'count', args)
      end.to raise_error(Services::Report::ArgumentsError)
    end

    it 'raises an error when no start_at is provided' do
      args.delete(:start_at)
      expect do
        report.send(:simple_stat_lookup, 'count', args)
      end.to raise_error(Services::Report::ArgumentsError)
    end

    it 'raises an error when no end_at is provided' do
      args.delete(:end_at)
      expect do
        report.send(:simple_stat_lookup, 'count', args)
      end.to raise_error(Services::Report::ArgumentsError)
    end

    it 'raises an error when an invalid group_by is provided' do
      args[:group_by] = ['register_id']
      expect do
        report.send(:simple_stat_lookup, 'count', args)
      end.to raise_error(Services::Report::ArgumentsError)
    end

    it 'raises an error when multiple group_by columns are provided' do
      args[:group_by] = ['entity_type', 'entity_id']
      expect do
        results = report.send(:simple_stat_lookup, 'count', args)
      end.to raise_error(Services::Report::ArgumentsError)
    end
  end
end
