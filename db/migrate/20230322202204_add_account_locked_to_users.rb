class AddAccountLockedToUsers < ActiveRecord::Migration[6.1]
  def change
        add_column :users, :account_locked, :boolean, default: false
        add_column :users, :account_locked_reason, :string
        add_column :users, :trial_expires_at, :datetime
  end
end
