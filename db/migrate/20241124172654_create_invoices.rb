class CreateInvoices < ActiveRecord::Migration[7.0]
  def change
    create_table :invoices do |t|
      t.references :owner, null: false, polymorphic: true, index: true
      t.references :payee_org, null: false, foreign_key: { to_table: :organizations }
      t.references :payor_org, null: false, foreign_key: { to_table: :organizations }
      t.datetime :date, null: false, index: true
      t.text :notes
      t.string :currency, null: false
      t.decimal :total, precision: 15, scale: 2, null: false
      t.timestamps
    end
  end
end
