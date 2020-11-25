class CreateUsersBoardsJoinTable < ActiveRecord::Migration[6.0]
  def change
    create_join_table :users, :boards do |t|
      t.index :user_id
      t.index :board_id
    end
  end
end
