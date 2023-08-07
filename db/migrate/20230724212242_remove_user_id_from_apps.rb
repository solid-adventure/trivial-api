class RemoveUserIdFromApps < ActiveRecord::Migration[7.0]
  def change
    remove_column :apps, :user_id, :integer
  end
end
