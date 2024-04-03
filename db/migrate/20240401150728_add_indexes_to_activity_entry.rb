class AddIndexesToActivityEntry < ActiveRecord::Migration[7.0]
  def change
    add_index :activity_entries, :payload, using: 'gin'
  end
end
