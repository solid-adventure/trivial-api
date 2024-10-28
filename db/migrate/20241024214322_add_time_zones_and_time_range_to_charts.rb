class AddTimeZonesAndTimeRangeToCharts < ActiveRecord::Migration[7.0]
  def change
    add_column :charts, :default_timezones, :string, array: true, null: false, default: ['America/New_York']
    add_column :charts, :default_time_range, :string, null: false, default: 'ytd'
  end
end
