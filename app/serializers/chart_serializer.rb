class ChartSerializer < ActiveModel::Serializer
  attributes :id, :dashboard_id, :register_id, :name, :chart_type, :color_scheme, :report_period, :report_groups

  def report_groups
    object.aliased_groups()
  end
end
