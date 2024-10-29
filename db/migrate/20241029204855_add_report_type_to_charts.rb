class AddReportTypeToCharts < ActiveRecord::Migration[7.0]
  def change
    add_column :charts, :report_type, :string, null: false, default: 'item_sum'
  end
end
