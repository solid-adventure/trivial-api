class CreateCustomers < ActiveRecord::Migration[6.0]
  def change
    create_table :customers do |t|
      t.string :name
      t.string :token
      t.string :billing_email

      t.timestamps
    end
  end
end
