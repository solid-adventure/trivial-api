class CreateActivityEntries < ActiveRecord::Migration[6.0]
  class App < ActiveRecord::Base
  end

  class Webhook < ActiveRecord::Base
    belongs_to :app, primary_key: :name
  end

  class ActivityEntry < ActiveRecord::Base
  end

  def up
    create_table :activity_entries do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :app, null: true, foreign_key: true
      t.uuid :update_id, null: true, index: true
      t.string :activity_type, null: false
      t.string :status
      t.string :source
      t.integer :duration_ms
      t.jsonb :payload
      t.jsonb :diagnostics
      t.timestamps
    end

    batch_count = (Webhook.count / 1000.0).ceil
    Webhook.includes(:app).find_in_batches.with_index do |webhooks, batch|
      puts "Converting webhooks batch # #{batch + 1} / #{batch_count}"
      ActivityEntry.transaction do
        webhooks.each do |webhook|
          ActivityEntry.create! do |entry|
            entry.user_id = webhook.user_id
            entry.app_id = webhook.app.id
            entry.activity_type = 'request'
            entry.status = webhook.status
            entry.source = webhook.source
            entry.payload = JSON.parse(webhook.payload) rescue nil
            entry.diagnostics = JSON.parse(webhook.diagnostics) rescue nil
            entry.created_at = webhook.created_at
            entry.updated_at = webhook.updated_at
          end
        rescue => e
          puts "Failed to import webhook##{webhook.id} - #{e}"
        end
      end
    end
  end

  def down
    drop_table :activity_entries
  end
end
