class DropShipmentsOrders < ActiveRecord::Migration[7.0]
  def change
    drop_table :orders
    drop_table :shipments
  end
end
