class AddSignChangeToCharts < ActiveRecord::Migration[7.0]
  def change
    add_column :charts, :invert_sign, :boolean, default: false, null: false
  end
end
