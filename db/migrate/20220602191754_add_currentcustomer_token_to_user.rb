class AddCurrentcustomerTokenToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :current_customer_token, :string
  end
end
