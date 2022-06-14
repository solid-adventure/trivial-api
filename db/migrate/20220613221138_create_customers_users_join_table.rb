class CreateCustomersUsersJoinTable < ActiveRecord::Migration[6.0]
  def change
    create_join_table :customers, :users  do |t|
      t.index :customer_id
      t.index :user_id
    end
  end
end
