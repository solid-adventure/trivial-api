class MigrateUserIdToOwnerIdApps < ActiveRecord::Migration[7.0]
  class TempApps < ActiveRecord::Base
    self.table_name = 'apps'
  end

  def up
    TempApps.find_each do |app|
      app.update_columns(owner_id: app.user_id, owner_type: 'User')
    end
  end

  def down
    TempApps.find_each do |app|
      app.update_columns(owner_id: nil, owner_type: nil)
    end
  end
end
