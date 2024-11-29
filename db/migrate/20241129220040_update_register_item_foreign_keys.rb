class UpdateRegisterItemForeignKeys < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :register_items, :apps,
      column: :app_id
    add_foreign_key :register_items, :invoices,
      column: :invoice_id,
      on_delete: :nullify
    add_reference :register_items, :invoice_item,
      null: true,
      foreign_key: { to_table: :invoice_items, on_delete: :nullify }
  end
end

