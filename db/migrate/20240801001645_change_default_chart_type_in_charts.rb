class ChangeDefaultChartTypeInCharts < ActiveRecord::Migration[7.0]
  def change
    change_column_default :charts, :chart_type, from: 'gross_revenue', to: 'table'

    Chart.where(chart_type: 'gross_revenue').update_all(chart_type: 'table')
  end
end
