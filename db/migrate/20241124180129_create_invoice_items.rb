class CreateInvoiceItems < ActiveRecord::Migration[7.0]
  def change
    create_table :invoice_items do |t|
      t.references :owner, null: false, polymorphic: true, index: true
      t.references :invoice, null: false, foreign_key: true
      t.string :income_account, null: false, index: true
      t.string :income_account_group, null: false, index: true
      t.decimal :quantity, precision: 15, scale: 4, null: false
      t.decimal :unit_price, precision: 15, scale: 4, null: false
      t.decimal :extended_amount, precision: 15, scale: 4, null: false

      t.timestamps
    end
  end
end
