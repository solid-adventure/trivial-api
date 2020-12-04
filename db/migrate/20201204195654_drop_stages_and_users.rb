class DropStagesAndUsers < ActiveRecord::Migration[6.0]
  def change
    drop_table :stages_users
  end
end
