# frozen_string_literal: true

class AddColumnsToUsers < ActiveRecord::Migration[6.0]
  def change
    # if no team -> id of "individual" in Team
    add_column :users, :team_id,  :integer, null: false
    # 0: member, 1: team_manager, 2: admin
    add_column :users, :role,     :integer, null: false, default: 0
    # 0: pending, 1: approved, 2: rejected
    add_column :users, :approval, :integer, null: false, default: 0
  end
end
