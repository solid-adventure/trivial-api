class CreateShipments < ActiveRecord::Migration[6.0]
  def change
    create_table :shipments do |t|

      t.integer :order_id
      t.integer :platform_id
      t.datetime :shipped_at
      t.integer :zone
      t.decimal :cost, :precision => 8, :scale => 2

      t.string :weight_units
      t.decimal :weight_value
      t.string :dims_units
      t.decimal :dims_length
      t.decimal :dims_width
      t.decimal :dims_height
      t.string :tracking_number

      t.string :to_company
      t.string :to_street1
      t.string :to_street2
      t.string :to_street3
      t.string :to_city
      t.string :to_state
      t.string :to_postal
      t.string :to_country
      t.string :to_country_iso2
      t.boolean :to_residential

      t.boolean :billed_dimensional

      t.decimal :insured_value, :precision => 8, :scale => 2
      t.decimal :insurance_cost, :precision => 8, :scale => 2

      t.string :customer_token, :null => false

      t.timestamps
    end
  end
end
