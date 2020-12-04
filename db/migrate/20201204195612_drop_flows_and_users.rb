class DropFlowsAndUsers < ActiveRecord::Migration[6.0]
  def change
    drop_table :flows_users
  end
end
