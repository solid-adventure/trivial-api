class CreateWebhooks < ActiveRecord::Migration[6.0]
  def change
    create_table :webhooks do |t|
      t.string :app_id
      t.json :payload
      t.string :source
      t.string :topic

      t.timestamps
    end
  end
end
