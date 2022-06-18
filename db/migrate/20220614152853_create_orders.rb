class CreateOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :orders do |t|

      t.string :platform_id
      t.string :platform_created_at
      t.string :platform_name, :null => false
      t.string :number
      t.string :shipping_method
      t.datetime :shipped_at
      t.decimal :subtotal, :precision => 8, :scale => 2
      t.decimal :taxes, :precision => 8, :scale => 2
      t.decimal :discounts, :precision => 8, :scale => 2
      t.decimal :shipping, :precision => 8, :scale => 2
      t.decimal :total, :precision => 8, :scale => 2
      t.string :customer_token, :null => false
      t.timestamps
    end
  end
end
