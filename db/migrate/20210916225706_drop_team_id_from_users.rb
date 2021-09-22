class DropTeamIdFromUsers < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :team_id
  end
end
