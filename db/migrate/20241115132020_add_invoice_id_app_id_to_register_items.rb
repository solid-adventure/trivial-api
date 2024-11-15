class AddInvoiceIdAppIdToRegisterItems < ActiveRecord::Migration[7.0]
  def change
    add_column :register_items, :invoice_id, :integer
    add_column :register_items, :app_id, :integer

    add_index :register_items, :invoice_id
    add_index :register_items, :app_id
  end
end
