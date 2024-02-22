class AddOrginatedAtToRegisterItems < ActiveRecord::Migration[7.0]
  def change
    add_column :register_items, :originated_at, :datetime
  end
end
