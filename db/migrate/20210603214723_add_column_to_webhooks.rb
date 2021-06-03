class AddColumnToWebhooks < ActiveRecord::Migration[6.0]
  def change
    add_column :webhooks, :diagnostics, :json
  end
end
