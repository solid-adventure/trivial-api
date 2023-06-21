class CreateCustomerTableDefinitions < ActiveRecord::Migration[6.1]
  def change
    create_table :customer_table_definitions do |t|
      t.string :table_name
      t.string :table_hash

      t.timestamps
    end
  end
end
