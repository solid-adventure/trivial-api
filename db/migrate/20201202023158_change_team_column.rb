class ChangeTeamColumn < ActiveRecord::Migration[6.0]
  def change
    change_column_null :users, :team_id, true
  end
end
