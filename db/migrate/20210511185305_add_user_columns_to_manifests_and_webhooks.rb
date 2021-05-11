class AddUserColumnsToManifestsAndWebhooks < ActiveRecord::Migration[6.0]
  def change
    add_column :webhooks, :user_id, :integer
    rename_column :manifests, :owner_id, :user_id
  end
end
