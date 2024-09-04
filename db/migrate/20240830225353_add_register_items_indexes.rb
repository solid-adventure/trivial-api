class AddRegisterItemsIndexes < ActiveRecord::Migration[7.0]

  disable_ddl_transaction!

  def change
    add_index :register_items, :originated_at, algorithm: :concurrently, if_not_exists: true
  end
end
