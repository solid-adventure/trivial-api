class ChangeJsonToJsonB < ActiveRecord::Migration[6.0]
  def up
    change_column :manifests, :content, :jsonb
    change_column :webhooks, :payload, :jsonb
    change_column :webhooks, :diagnostics, :jsonb
  end

  def down
    change_column :manifests, :content, :json
    change_column :webhooks, :payload, :json
    change_column :webhooks, :diagnostics, :json
  end

end
