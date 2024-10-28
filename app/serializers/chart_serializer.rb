class ChartSerializer < ActiveModel::Serializer
  attributes :id, :dashboard_id, :register_id, :name, :chart_type, :color_scheme, :invert_sign, :report_period, :default_timezones, :default_time_range, :time_range_bounds, :report_groups

  def report_groups
    object.aliased_groups
  end

  def time_range_bounds
    object.time_range_bounds
  end
end
