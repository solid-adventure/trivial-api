class CreateInvoices < ActiveRecord::Migration[7.0]
  def change
    create_table :invoices do |t|
      t.datetime :date, null: false
      t.integer :payee_org_id, null: false
      t.integer :payor_org_id, null: false
      t.integer :register_id, null: false
      t.string :currency, null: false
      t.decimal :total, precision: 15, scale: 2, null: false
      t.text :notes
      t.references :owner, null: false, polymorphic: true, index: true
      t.timestamps
    end

    add_foreign_key :invoices, :organizations, column: :payee_org_id
    add_foreign_key :invoices, :organizations, column: :payor_org_id

    add_index :invoices, :payee_org_id
    add_index :invoices, :payor_org_id
    add_index :invoices, :date

  end
end
