class CreateBoardsAndUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :boards_users do |t|
      t.belongs_to :board
      t.belongs_to :user
    end
  end
end
