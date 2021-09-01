class RenameUserColumn < ActiveRecord::Migration[6.0]
  def change
    rename_column :users, :reset_password_token_sent_at, :reset_password_sent_at
  end
end
