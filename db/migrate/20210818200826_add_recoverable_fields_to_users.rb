class AddRecoverableFieldsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_token_sent_at, :datetime
    add_column :users, :allow_password_change, :boolean, default: false
    add_index :users, :reset_password_token, unique: true
  end
end
