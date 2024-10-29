# app/model/chart.rb

class Chart < ApplicationRecord
  audited associated_with: :dashboard

  VALID_REPORT_PERIODS = %w[day week month quarter year].freeze
  VALID_REPORT_TYPES = %w[item_count item_sum item_average].freeze
  VALID_TIME_RANGES = %w[today yesterday last_week last_month last_year ytd].freeze

  validates :name,
    presence: true,
    uniqueness: {
      scope: %i[dashboard register],
      message: "%{value} already exists as a chart name for this dashboard and register"
    }
  validates :chart_type,
    presence: true
  validates :color_scheme,
    presence: true
  validates :report_period,
    presence: true,
    inclusion: {
      in: VALID_REPORT_PERIODS,
      message: "%{value} is not a valid report period"
    }
  validates :report_type,
    presence: true,
    inclusion: {
      in: VALID_REPORT_TYPES,
      message: "%{value} is not a valid report type"
    }
  validates :default_time_range,
    presence: true,
    inclusion: {
      in: VALID_TIME_RANGES,
      # any string with format 'last_n_days' where n is Integer && n > 0 is valid
      unless: -> { default_time_range&.match?(/\Alast_[1-9]\d*_days\z/) },
      message: "%{value} is not a valid time range"
    }
  validates :default_timezones, presence: true
  validates_each :default_timezones do |record, attr, value|
    value&.each do |zone|
      record.errors.add(attr, "#{zone} is not a valid time zone") unless ActiveSupport::TimeZone[zone]
    end
  end

  belongs_to :dashboard, inverse_of: :charts
  belongs_to :register, inverse_of: :charts

  def aliased_groups
    register.meta.each_with_object({}) do |(column, label), groups|
      groups[label] = __send__(column)
    end
  end

  def unaliased_groups
    register.meta.each_with_object({}) do |(column, _), groups|
      groups[column] = __send__(column)
    end
  end

  def unalias_groups!(groups)
    meta = register.meta.invert
    groups.transform_keys do |key|
      raise "#{key} is not a valid alias on this chart's groups" unless meta.key? key
      meta[key]
    end
  end

  def default_timezone
    default_timezones.first
  end

  def time_range_bounds(timezone: default_timezone)
    zone = if default_timezones.include?(timezone)
             timezone
           else
             raise ArgumentError, "Invalid timezone #{timezone}. Must be one of: #{default_timezones.join(', ')}"
           end

    Time.use_zone(zone) do
      case default_time_range
      when 'today'
        {
          start_at: Time.current.beginning_of_day.iso8601,
          end_at: Time.current.end_of_day.iso8601
        }
      when 'yesterday'
        {
          start_at: Time.current.yesterday.beginning_of_day.iso8601,
          end_at: Time.current.yesterday.end_of_day.iso8601
        }
      when 'last_week'
        {
          start_at: Time.current.last_week.iso8601,
          end_at: Time.current.last_week.end_of_week.iso8601
        }
      when 'last_month'
        {
          start_at: Time.current.last_month.beginning_of_month.iso8601,
          end_at: Time.current.last_month.end_of_month.iso8601
        }
      when 'last_year'
        {
          start_at: Time.current.last_year.beginning_of_year.iso8601,
          end_at: Time.current.last_year.end_of_year.iso8601
        }
      when 'ytd'
        {
          start_at: Time.current.beginning_of_year.iso8601,
          end_at: Time.current.iso8601
        }
      when /\Alast_([1-9]\d*)_days\z/ # last_n_days where n > 0
        days = $1.to_i
        {
          start_at: (Time.current.beginning_of_day - days.days).iso8601,
          end_at: Time.current.yesterday.end_of_day.iso8601
        }
      end
    end
  end
end
