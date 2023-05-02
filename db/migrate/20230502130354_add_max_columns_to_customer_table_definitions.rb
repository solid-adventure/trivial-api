class AddMaxColumnsToCustomerTableDefinitions < ActiveRecord::Migration[6.1]
  def change
    add_column :customer_table_definitions, :max_columns, :integer
  end
end
