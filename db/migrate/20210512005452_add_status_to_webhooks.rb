class AddStatusToWebhooks < ActiveRecord::Migration[6.0]
  def change
    add_column :webhooks, :status, :string
  end
end
