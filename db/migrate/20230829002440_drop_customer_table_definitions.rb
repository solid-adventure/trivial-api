class DropCustomerTableDefinitions < ActiveRecord::Migration[7.0]
  def change
    drop_table :customer_table_definitions
  end
end
