class AddScheduleToApps < ActiveRecord::Migration[6.1]
  def change
    add_column :apps, :schedule, :jsonb
  end
end
