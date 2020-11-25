class AddColumnsToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :name,     :string
    # if no team -> id of "individual" in Team
    add_column :users, :team_id,  :integer
    # 0: admin, 1: team_manager, 2: user
    add_column :users, :role,     :integer, null: false, default: 2
    # 0: approved, 1: pending, 2, not_approved
    add_column :users, :approval, :integer, null: false, default: 2
  end
end
