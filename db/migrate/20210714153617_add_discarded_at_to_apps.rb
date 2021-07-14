class AddDiscardedAtToApps < ActiveRecord::Migration[6.0]
  def change
    add_column :apps, :discarded_at, :datetime
    add_index :apps, :discarded_at
  end
end
