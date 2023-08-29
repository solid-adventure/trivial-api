class DropWebhooksTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :webhooks
  end
end
