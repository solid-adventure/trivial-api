# app/model/chart.rb

class Chart < ApplicationRecord
  audited associated_with: :dashboard

  REPORT_PERIODS = %w[day week month quarter year]

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
      in: REPORT_PERIODS,
      message: "%{value} is not a valid report period"
    }

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
end
