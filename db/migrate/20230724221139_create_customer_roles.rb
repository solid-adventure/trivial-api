class CreateCustomerRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :customer_roles do |t|
      t.string :name
      t.text :description
      t.bigint :customer_id

      t.timestamps
    end
  end
end
